# Databricks Module Rules — Extensions

Working document. Databricks-specific rules that extend the general Terraform rules in [TERRAFORM_RULES.md](./TERRAFORM_RULES.md). Read that first; this document captures only the deltas required by Databricks-specific structural facts.

A rule belongs here only if it's required by something intrinsic to Databricks (e.g., two API surfaces, async workspace creation, UC's account-scoped+workspace-bound nature). Anything that's just good Terraform belongs in TERRAFORM_RULES.md.

---

## Classification Axes

Every Databricks module is classified across three axes. These axes govern module naming, directory structure, provider wiring, and lifecycle decisions.

### Axis 1 — Provider Surface

The `databricks/databricks` provider has two distinct API surfaces that cannot share a provider instance. This is a hard structural boundary.

| Surface | Description | Provider Config |
|---|---|---|
| **Account** | Account-level API. Workspace provisioning, networking, storage, CMKs, log delivery, account identity. | `host = "https://accounts.cloud.databricks.com"` (or Azure/GCP equivalent) |
| **Unity Catalog** | Bridges account and workspace. Metastore creation and assignment, storage credentials, external locations. Requires both provider instances. | Both `databricks.account` and `databricks.workspace` via `configuration_aliases` |
| **Workspace** | Workspace-level API. Catalogs, schemas, grants, clusters, jobs, secrets, permissions. Entirely cloud-agnostic. | `host = "<workspace-url>"` |

### Axis 2 — Cloud

Account-side resources are cloud-specific; workspace-side resources are cloud-agnostic. This asymmetry is intrinsic.

| Cloud | Scope |
|---|---|
| **AWS** | Account-level modules (VPC, IAM, S3, PrivateLink wiring). Includes commercial and GovCloud (civilian + DoD) via the `databricks_gov_shard` input — see Rule 1.5. |
| **Azure** | Account-level modules (VNet, Access Connector, ADLS Gen2, Private Endpoints). Includes commercial and Azure Government via the `azurerm` provider `environment` setting at the root composition — see Rule 1.5. |
| **GCP** | Account-level modules (VPC, GCS, PSC, service accounts) |
| **Cloud-agnostic** | All Unity Catalog and Workspace modules; shared account-level concerns (identity, log delivery) |

### Axis 3 — Platform Tier

Databricks platform tiers gate which resources, features, and configurations are valid for a given workspace. A module must document its minimum required tier. Deploying a tier-gated resource to a workspace below that tier will fail at apply time (the provider does no plan-time tier check) or in some cases create the resource without enforcement.

| Tier | Description | Examples of gated features |
|---|---|---|
| **Standard** | Base tier. Limited feature set. | Basic compute, jobs, notebooks |
| **Premium** | Adds identity, compliance, and governance features. | Unity Catalog, SCIM, IP access lists, cluster policies with ACLs, SSO |
| **Enterprise** | Adds advanced security and compliance controls. | Compliance Security Profile, enhanced monitoring, automatic cluster updates, User Isolation mode |

GovCloud workspaces have the Compliance Security Profile auto-enabled; this is a cloud-level fact (Axis 2), not a tier (Axis 3). GovCloud workspaces still operate at Premium or Enterprise tier within Databricks.

### Axis 4 — Lifecycle

| Lifecycle | Description | Change frequency | Examples |
|---|---|---|---|
| **Deployment** | Create-once infrastructure. Expensive or impossible to recreate. | Rare | Workspace, network, metastore, CMKs |
| **Bootstrap** | Run-once account setup. Establishes the baseline before workspaces exist. | Once | Account groups, admin role assignments, initial UC admin grants |
| **Operational** | Ongoing configuration. Changes as teams, workloads, and policies evolve. | Frequent | Grants, group memberships, IP access lists, secret scopes, cluster policies |

---

## 1. Identify

How we decide what becomes a Databricks module — extensions to the general rules.

**1.1 — Provider surface is a hard module boundary.** Account-level Databricks operations (workspace creation, account identity, metastore creation) and workspace-level operations (catalogs, grants, secrets, jobs, permissions) use different provider configurations and cannot share a provider instance. A module touching both surfaces is a Unity Catalog bridging module and must declare both providers via `configuration_aliases`. A module touching only one surface has that boundary as a hard limit.

**1.2 — Cloud asymmetry drives where modules split.** Account-side modules are cloud-specific (AWS, Azure, GCP each have entirely different account-level resource trees). Workspace-side modules are cloud-agnostic (the workspace API is uniform). Unity Catalog modules are cloud-agnostic for Databricks resources but accept cloud-specific storage credentials as inputs. The module tree splits on cloud at the account layer only.

**1.3 — Two-phase composition is mandatory.** The workspace host URL is produced by workspace creation and is required to authenticate the workspace provider. A single Terraform configuration cannot both create a workspace AND configure things inside it under the same provider scope. Modules that configure workspace internals must accept `workspace_url` (or workspace_id + a constructed provider) as input — they cannot create the workspace they configure.

**1.4 — Cloud-side + Databricks-side 1:1 pairing belongs in one module.** When a cloud resource and its Databricks registration form one indivisible function, they live in one module. Examples:
- AWS IAM role + `databricks_mws_credentials` (the credentials Databricks uses)
- AWS S3 bucket + `databricks_mws_storage_configurations` (the storage Databricks uses)
- AWS VPC + `databricks_mws_networks` (the network Databricks uses)
- Azure Access Connector + `databricks_storage_credential` (the UC storage credential on Azure)
- GCP VPC + `databricks_mws_networks`

Splitting along the cloud↔Databricks boundary produces thin wrappers. Pairing produces a real abstraction. Only split when either side has independent reuse.

**1.5 — GovCloud is parameterization, not a separate tree.** AWS GovCloud (civilian and DoD) shares the same Terraform module tree as AWS commercial. A single `databricks_gov_shard` input (null / "civilian" / "dod") drives computed locals for partition, host URLs, cross-account account IDs, endpoint names, and PrivateLink service attachment names. Modules do not branch on gov at the resource level — all variance is expressed through inputs and locals. Azure Government is parameterized via the `azurerm` provider `environment = "usgovernment"`, a provider-level concern handled in root compositions.

---

## 2. Structure

How a Databricks module is laid out — extensions to the general rules.

**2.1 — Module names match Databricks concepts, not provider resource names.** Use `workspace`, `metastore`, `catalog` — not `mws_workspaces`, `metastore_assignment`. Resource type names leak the provider's internal taxonomy; concept names raise abstraction.

**2.2 — `configuration_aliases` declared for any multi-provider module.** Modules requiring both account and workspace provider instances (Unity Catalog bridging modules; any module crossing the surface boundary) declare them via `terraform { required_providers { databricks { configuration_aliases = [databricks.account, databricks.workspace] } } }`. Callers pass both provider aliases at the module call site.

**2.3 — Module documents minimum platform tier.** Every module declares in its README the minimum Databricks platform tier required (Standard, Premium, Enterprise). The Databricks Terraform provider does not expose tier as a plan-time attribute, so enforcement is empirical: per Rule 4.1, tier-gated modules MUST include a `terraform test` apply-command case verifying that the resource fails loudly when applied against an insufficient tier. README documentation + apply-command tier-failure test together constitute the complete enforcement model.

**2.4 — Cloud credential is an object-typed input, not a scalar.** Modules consuming a cloud credential (UC storage credential, metastore data access, log delivery) accept an `object` input with `optional()` per-cloud fields (e.g., `{ aws_iam_role = optional(object({...})), azure_managed_identity = optional(object({...})), gcp_service_account = optional(object({...})) }`). Only the field relevant to the cloud in use is populated. This avoids stringly-typed cloud toggles and lets the same module work across clouds.

---

## 3. Build

How a Databricks module is implemented — extensions to the general rules.

**3.1 — `time_sleep` is the sanctioned race-condition workaround.** `time_sleep` is a resource, not a provisioner — it does not violate the "no provisioners" rule. Use it only for documented race conditions where Terraform's natural dependency graph is insufficient:
- AWS IAM role propagation before resource use (typically 30s)
- Workspace DNS propagation before workspace provider configuration
- Workspace permission API readiness after workspace creation (typically 20s)

Every `time_sleep` block carries a comment naming the race condition it addresses.

**3.2 — `ignore_changes` discipline for human-vs-Terraform ownership.** Specific Databricks fields are commonly modified outside Terraform and require `lifecycle { ignore_changes = [...] }`. Illustrative cases (not exhaustive):
- `databricks_mws_workspaces.custom_tags` — humans add tags via UI
- `azurerm_databricks_workspace.enhanced_security_compliance.compliance_security_profile_standards` on Azure — managed via `azapi_update_resource` workaround
- `aws_s3_bucket_policy.policy` on root storage — Databricks modifies post-creation
- `databricks_group.members` / `owners` — when SCIM/AIM is active, IdP owns membership
- `databricks_mws_permission_assignment.principal_id` — resolved IDs change with SCIM syncs

Each `ignore_changes` carries a comment naming the source of the external mutation. Add new entries to this rule as they're discovered.

**3.3 — Identity model conditionality.** Modules that touch identity (groups, users, service principals) must document which identity models they support: native, SCIM, or AIM. When SCIM or AIM is active, modules manage *references* to IdP-owned identities (via `data` sources) and `ignore_changes` on membership — they do NOT create users or groups. Modules that create identities are valid only for native identity deployments.

---

## 4. Test

How a Databricks module is validated — extensions to the general rules.

**4.1 — Provider tier failures must be exercised by tests.** Where a module uses tier-gated resources, an apply-command test against a workspace below the required tier verifies that failure is loud and immediate, not silent. The module's README minimum-tier claim is validated empirically.

---

## 6. Maintain

How Databricks modules are kept healthy — extensions to the general rules.

**6.1 — `databricks/databricks` provider churn requires explicit minimum-version pinning per feature.** The provider ships new resources and behavior changes frequently. Module `versions.tf` lower bounds reflect the specific feature used (e.g., `databricks = ">= 1.50"` because the module uses `databricks_account_network_policy` introduced in 1.50), not a generic "any recent version." The reason is captured in a comment next to the constraint.

---

_Sections 5 (Evolve) and 7 (Deprecate) have no Databricks-specific extensions. The general rules in TERRAFORM_RULES.md apply._
