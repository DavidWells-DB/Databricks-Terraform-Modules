# Module Variability

Research document. Captures the dimensions of variability that Databricks Terraform modules must handle: cloud, platform tier, network primitives, encryption, identity, brownfield adoption, lifecycle. This is the requirement-driven foundation for `MODULE_CANDIDATES.md`.

The intent is NOT to describe deployments — it's to describe the input space modules must accept and the constraints they must respect.

Sources: Databricks docs, AWS/Azure/GCP docs, Terraform provider registry, example repos (terraform-databricks-sra, Databricks-Terraform-Monorepo, terraform-databricks-examples).

---

## Dimension 1 — Cloud and Cloud Tier

### Commercial Clouds
| Cloud | Account Host | Key Structural Differences |
|---|---|---|
| AWS | `https://accounts.cloud.databricks.com` | MWS-pattern workspace creation, IAM cross-account role, S3 root storage, KMS |
| Azure | ARM-managed workspace (`azurerm_databricks_workspace`), no MWS pattern | Access Connector + ADLS Gen2 for storage, Key Vault for CMK, Azure AD for identity |
| GCP | `https://accounts.gcp.databricks.com` | MWS-pattern, GCS root storage, GCP service account impersonation, PSC for private connectivity |

### Government Clouds
| Cloud Tier | Account Host | Partition | Databricks AWS Account ID | Key Differences |
|---|---|---|---|---|
| AWS GovCloud (Civilian) | `https://accounts.cloud.databricks.us` | `aws-us-gov` | `044793339203` | PrivateLink mandatory, compliance profile auto-enabled, no Service Direct endpoint, limited system tables, no Marketplace |
| AWS GovCloud (DoD / IL5) | `https://accounts-dod.cloud.databricks.mil` | `aws-us-gov` | `170661010020` | All of civilian + `.mil` TLD, DoD-specific PSC attachment names, manual onboarding required, more restricted feature set |
| Azure Government | Same workspace URL format; Azure subscription scoped to Government | n/a | n/a | `azurerm` provider requires `environment = "usgovernment"`, CMK mandatory for IL5, non-HIPAA/PCI compliance standards require `azapi_update_resource` workaround |

**Module implication:** AWS commercial and GovCloud share the same module tree. GovCloud is parameterized via `databricks_gov_shard` (null / "civilian" / "dod") and AWS partition — all ARNs, endpoint names, account IDs, and host URLs are computed locals from these two inputs. A separate module tree is not warranted. Azure Government similarly shares the same module tree as Azure commercial, parameterized at the `azurerm` provider via `environment = "usgovernment"` at the root composition (not at the module layer).

### Unity Catalog Cross-Account AWS ARNs
| Environment | Cross-Account ARN |
|---|---|
| Commercial | `arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL` |
| GovCloud Civilian | `arn:aws-us-gov:iam::044793339203:role/unity-catalog-prod-UCMasterRole-1QRFA8SGY15OJ` |
| GovCloud DoD | `arn:aws-us-gov:iam::170661010020:role/unity-catalog-prod-UCMasterRole-1DI6DL6ZP26AS` |

---

## Dimension 2 — Platform Tier

Standard tier is end-of-life (no new creation after April 2026; auto-upgraded October 2026). Active tiers are Premium and Enterprise.

**The Terraform provider does NOT enforce tier requirements at plan time. All tier gates fail at apply time.**

| Resource / Feature | Minimum Tier | Failure Mode |
|---|---|---|
| `databricks_metastore` + Unity Catalog | Premium | Fails at apply |
| `databricks_cluster` with `data_security_mode = "USER_ISOLATION"` | Premium (UC required) | Fails at apply |
| `databricks_permissions` object-level ACLs | Premium | Fails at apply (403) |
| `databricks_cluster_policy` with ACLs | Premium | Fails at apply |
| `databricks_mws_customer_managed_keys` | Premium | Fails at apply |
| `databricks_ip_access_list` | Premium (Azure/GCP) · Enterprise (AWS) | Creates but silently not enforced if `enableIpAccessLists` not set; fails at apply on wrong tier |
| `databricks_sql_endpoint` with `enable_serverless_compute = true` | Premium | Fails at apply |
| SCIM provisioning | Premium | Token generation fails |
| `databricks_mws_network_connectivity_config` (serverless NCC) | Premium | Fails at apply |
| `databricks_compliance_security_profile_workspace_setting` | Enterprise | Fails at apply |
| `databricks_enhanced_security_monitoring_workspace_setting` | Enterprise | Fails at apply |
| `databricks_automatic_cluster_update_workspace_setting` | Enterprise | Fails at apply |
| Azure `sku = "premium"` → maps to Premium tier | n/a | Plan-time schema validation |
| GovCloud — compliance profile auto-enabled | GovCloud environment | Cannot be disabled |

**Module implication:** Every module that uses a tier-gated resource must document its minimum tier in its README and variables. Modules should NOT attempt to validate tier at plan time — the provider doesn't expose tier as a queryable attribute. Document it; let apply-time errors surface clearly.

---

## Dimension 3 — Network Topology

### AWS Network Topologies

| Topology | Classic Compute | User Access | Required Terraform Resources | Constraints |
|---|---|---|---|---|
| Databricks-managed VPC | Public IPs | Public | `databricks_mws_workspaces` only | No PrivateLink possible |
| Customer-managed VPC, no PrivateLink | SCC (no public IPs) | Public | `aws_vpc`, subnets, SGs, `databricks_mws_networks` | NAT required for egress |
| Back-end PrivateLink only | Private (VPC endpoints) | Public | + `aws_vpc_endpoint` ×2, `databricks_mws_vpc_endpoint` ×2, `databricks_mws_private_access_settings` | Enterprise required |
| Front-end PrivateLink only | SCC or public | Private (from transit VPC) | + `aws_vpc_endpoint` (Service Direct), `databricks_mws_private_access_settings` | No customer VPC required |
| Full PrivateLink (front + back) | Private | Private | All of above | Enterprise, customer VPC, DNS resolution required inside VPC |
| **GovCloud: Full PrivateLink mandatory** | Private | Private | Same as full PrivateLink + GovCloud-specific service attachment names | PrivateLink is not optional on GovCloud |
| Hub-and-spoke with Transit Gateway | Private (via TGW) | Private (via hub) | + TGW resources, shared PrivateLink endpoints in hub | VPC endpoint DNS must work cross-VPC |

**Serverless NCC (independent of classic topology):**
- `databricks_mws_network_connectivity_config` (account-level, regional)
- `databricks_mws_ncc_binding` (per workspace)
- `databricks_mws_ncc_private_endpoint_rule` (per resource to reach privately)
- `databricks_account_network_policy` + `databricks_workspace_network_option`
- Limit: 10 NCCs per region, max 50 workspaces per NCC, 30 S3 + 100 VPC endpoints per NCC region

### Azure Network Topologies

| Topology | Classic Compute | User Access | Key Resources |
|---|---|---|---|
| Public (no VNet injection) | Public IPs | Public | `azurerm_databricks_workspace` only |
| VNet injection + SCC | SCC (no public IPs) | Public | + `azurerm_virtual_network`, host/container subnets, NSGs |
| VNet injection + back-end Private Link | Private | Public | + `azurerm_private_endpoint` (`databricks_ui_api`), private DNS zone |
| VNet injection + full PrivateLink (hub-spoke) | Private | Private | + `azurerm_private_endpoint` ×3 (back-end + front-end + browser_auth), hub firewall, VNet peering |

**Azure serverless NCC** — same `databricks_mws_*` resources as AWS. Azure-specific constraint: DBFS NCC requires both `blob` and `dfs` subresource rules. Legacy serverless subnet allowlists deprecated June 2026; must migrate to `AzureDatabricksServerless` service tag.

### GCP Network Topologies

| Topology | Classic Compute | User Access | Key Resources |
|---|---|---|---|
| Databricks-managed VPC | Public | Public | `databricks_mws_workspaces` only |
| Customer-managed VPC, no PSC | SCC | Public via NAT | `google_compute_network`, subnetwork, router, NAT, `databricks_mws_networks` |
| Customer-managed VPC + PSC | Private | Private | + `google_compute_forwarding_rule` ×2, `google_compute_address` ×2, `google_dns_managed_zone`, `databricks_mws_vpc_endpoint` ×2, `databricks_mws_private_access_settings` |
| Serverless-only workspace | n/a | Public | `databricks_mws_workspaces` with `compute_mode = "SERVERLESS"` |

---

## Dimension 4 — Encryption

The Terraform provider does not enforce encryption requirements at plan time. All CMK settings are immutable after workspace creation.

| Encryption Domain | AWS | Azure | GCP | Notes |
|---|---|---|---|---|
| Managed services (notebooks, configs) | `databricks_mws_customer_managed_keys` (MANAGED_SERVICES) + `aws_kms_key` | `azurerm_databricks_workspace` (`managed_services_cmk_key_vault_key_id`) | `databricks_mws_workspaces` (`managed_services_customer_managed_key_id`) | Set at creation; immutable |
| Workspace storage / DBFS | `databricks_mws_customer_managed_keys` (STORAGE) + `aws_s3_bucket_server_side_encryption_configuration` | `azurerm_databricks_workspace_root_dbfs_customer_managed_key` (post-creation resource) | `databricks_mws_workspaces` (`storage_customer_managed_key_id`) | Azure requires separate post-creation registration |
| Managed disks / EBS | Inherits from managed services key or AWS default | `azurerm_databricks_workspace` (`managed_disk_cmk_key_vault_key_id`) | Not supported | Azure-only; `managed_disk_cmk_rotation_to_latest_version_enabled` controls rotation |
| Unity Catalog storage | Cloud-native (`aws_s3_bucket` SSE-KMS) | Cloud-native (`azurerm_storage_account` CMK) | Cloud-native (`google_kms_crypto_key`) | Encryption at cloud storage layer, not Databricks layer |
| Secrets store | Cloud-native (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager) | Same | Same | Databricks acts as proxy; not configurable via `databricks_*` resources |

**GovCloud/FedRAMP/IL5:** CMK for managed services AND workspace storage is **required**, not optional.

---

## Dimension 5 — Identity Model

| Model | Terraform Role | Resources | `ignore_changes` Required? |
|---|---|---|---|
| **Native** | Full ownership | `databricks_user`, `databricks_group`, `databricks_group_member`, `databricks_service_principal` | No |
| **SCIM** (legacy, pre-Aug 2025) | Manages group structure + permissions; IdP owns membership | `databricks_group` (structure only), `databricks_permissions`, grants | Yes — `members`, `owners` on groups synced by IdP |
| **Automatic Identity Management (AIM)** (default post-Aug 2025, Entra ID / Azure AD) | Manages permissions and catalog grants; Entra ID owns users/groups/membership | Same as SCIM pattern | Yes — `members`, `owners` on AIM-managed groups |

**Account-level vs workspace-level identity:**
- Modern pattern: account-level groups via `databricks.mws` provider, assigned to workspaces via `databricks_mws_permission_assignment`
- Legacy: workspace-local users/groups — do not create in new modules

**Service principals:**
- Created via `databricks_service_principal` at account level
- Cloud-specific federation: Azure AD app registration (`azuread_*`), AWS OIDC, GCP Workload Identity
- Account roles via `databricks_service_principal_role`; workspace roles via `databricks_permission_assignment`

**SSO:** No Terraform resource. Configured in account console or IdP admin portal before Terraform runs.

**What Terraform cannot manage when SCIM/AIM is active:**
- User creation / deletion (IdP is source of truth)
- Group membership sync (managed by IdP sync)
- SSO credentials

---

## Dimension 6 — Brownfield / Adoption Patterns

Per Rule 2.7 (TERRAFORM_RULES.md), modules do NOT toggle between "create" and "adopt existing" via null-coalesce inputs. Brownfield is a root-composition concern: the root either calls a creation module or uses a `data` source, then passes the resulting ID/object to the consuming module. The consuming module never knows which path produced the inputs.

This table documents how each resource is adopted at the root, NOT module behaviors.

| Resource | Adoption mechanism at root | Terraform `import` support | Key `ignore_changes` on adopted resource |
|---|---|---|---|
| Workspace | `data "databricks_mws_workspaces"` or `terraform import` | Yes | `custom_tags` |
| VPC / VNet | `data "aws_vpc"` / `data "azurerm_virtual_network"` / `data "google_compute_network"` | Not for VPC itself; `import` blocks supported | n/a |
| Metastore | `data "databricks_metastore"` by name, or `terraform import` | Yes | n/a |
| IAM roles / Access Connectors | `data "aws_iam_role"` / `data "azurerm_databricks_access_connector"` | Yes | n/a |
| KMS keys | `data "aws_kms_key"` / `data "azurerm_key_vault_key"` | Yes (by ARN/ID) | n/a |
| S3 / ADLS / GCS bucket | `data "aws_s3_bucket"` / `data "azurerm_storage_account"` / `data "google_storage_bucket"` | Yes | `policy` (Databricks modifies post-creation) |
| SCIM/AIM-managed groups | `data "databricks_group"` only — never create in any module | n/a | `members`, `owners` |

**E1 → E2 migration:** Not a Terraform concern. Workspaces can be imported post-migration.

---

## Dimension 7 — Lifecycle (Deployment / Bootstrap / Operational)

Cuts across all other dimensions. Determines change frequency and `ignore_changes` discipline within a module.

| Lifecycle | Change Frequency | `ignore_changes` Common? | Examples |
|---|---|---|---|
| **Deployment** (create-once) | Rare | Sometimes (for fields Databricks modifies post-creation) | Workspace, network, metastore, CMKs, PrivateLink endpoints |
| **Bootstrap** (run-once setup) | Once | Rarely | Account groups, admin assignments, initial UC grants, compliance settings |
| **Operational** (ongoing) | Frequent | Often (for fields humans edit in UI) | Grants, group memberships under SCIM/AIM, IP access lists, cluster policies, secret scopes |

**Human-vs-Terraform ownership conflicts** — fields that are commonly edited in UI and require `ignore_changes`:
- `custom_tags` on workspaces and clusters
- `compliance_security_profile_standards` on Azure workspaces
- Cluster `state`, `autotermination_minutes` when humans manage cluster lifecycle
- Group `members`, `owners` when IdP manages identity
- S3 bucket `policy` (Databricks modifies post-creation)
- GCP CMEK settings (register once, managed separately)
