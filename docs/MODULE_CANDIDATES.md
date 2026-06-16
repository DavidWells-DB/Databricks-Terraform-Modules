# Module Candidates

Research document. Each module candidate is evaluated against the rules in [TERRAFORM_RULES.md](./TERRAFORM_RULES.md) and [DATABRICKS_RULES.md](./DATABRICKS_RULES.md).

---

## Modules vs. Topology

**A module is a primitive that the cloud provides** (VPC, PrivateLink endpoints, Network Firewall, Transit Gateway, etc.), paired with its Databricks-side registration where applicable. Each module is one meaningful abstraction over its underlying cloud resources.

**Topology is a composition of primitives at a layer above.** Composition lives in root configurations, not in the module catalog.

The module catalog lists primitives only.

---

## Classification and Naming

Per module:
- **Provider surface:** Account / Unity Catalog / Workspace
- **Cloud:** AWS / Azure / GCP / Agnostic (`dbx` prefix)
- **Lifecycle:** Deployment / Bootstrap / Operational

Module naming convention: `<cloud>-<surface>-<name>` where `<cloud>` ∈ { `aws`, `azure`, `gcp`, `dbx` } and `<surface>` ∈ { `account`, `uc`, `workspace` }. `dbx` denotes cloud-agnostic Databricks modules.

Minimum platform tier documented per module (Rule 2.3 Databricks). Rule 1.5 Databricks: AWS GovCloud (civilian + DoD) is parameterized via `databricks_gov_shard` input on AWS modules.

---

## Account Layer — AWS (incl. GovCloud)

GovCloud is parameterization via `databricks_gov_shard` (null / "civilian" / "dod") in every AWS account module. Partition, host URLs, cross-account account IDs, endpoint names, and PrivateLink service attachment names are computed locals from this input.

---

### aws-account-workspace-credentials
`Account | AWS | Bootstrap`

**Purpose:** Creates the AWS IAM cross-account role granting Databricks control plane management permissions and registers it as Databricks credentials.

**Resources:** `aws_iam_role`, `aws_iam_role_policy`, `time_sleep` (IAM propagation), `databricks_mws_credentials`; data sources: `databricks_aws_assume_role_policy`, `databricks_aws_crossaccount_policy`

**Provider requirements:** `aws`, `databricks.account`

**Inputs:** `databricks_account_id`, `aws_partition`, `databricks_gov_shard`, `role_name`, optional `vpc_id` for condition scoping

**Outputs:** `credentials_id`, `role_arn`, `role_name`

**Notes:**
- Minimum tier: Premium
- GovCloud: Databricks AWS account IDs differ per shard (commercial: `414351767826`, civilian: `044793339203`, DoD: `170661010020`)
- `time_sleep` (30s) before `databricks_mws_credentials` references the role

**Sources:** `terraform-databricks-sra/aws/tf/credential.tf`

---

### aws-account-encryption-keys
`Account | AWS | Bootstrap`

**Purpose:** Creates customer-managed KMS keys for managed services and workspace storage encryption, and registers them as Databricks customer-managed keys.

**Resources:** `aws_kms_key` ×2, `aws_kms_alias` ×2, `databricks_mws_customer_managed_keys` (managed services + storage)

**Provider requirements:** `aws`, `databricks.account`

**Inputs:** `aws_partition`, `databricks_account_id`, `cross_account_role_arn`, `aws_account_id`, `databricks_gov_shard`

**Outputs:** `managed_services_key_id` (Databricks CMK ID), `workspace_storage_key_id`, key ARNs

**Notes:** Minimum tier: Premium. GovCloud: CMK required.

**Sources:** `terraform-databricks-sra/aws/tf/cmk.tf`

---

### aws-account-workspace-storage
`Account | AWS | Deployment`

**Purpose:** Creates an S3 bucket for workspace root storage (DBFS) and registers it as a Databricks storage configuration.

**Resources:** `aws_s3_bucket`, `aws_s3_bucket_versioning`, `aws_s3_bucket_server_side_encryption_configuration`, `aws_s3_bucket_public_access_block`, `aws_s3_bucket_policy`, `databricks_mws_storage_configurations`; data source: `databricks_aws_bucket_policy`

**Provider requirements:** `aws`, `databricks.account`

**Inputs:** `resource_prefix`, `aws_partition`, `databricks_account_id`, `databricks_gov_shard`, optional `kms_key_arn`

**Outputs:** `storage_configuration_id`, `bucket_name`, `bucket_arn`

**Notes:** Minimum tier: Premium. `ignore_changes = [policy]` (Databricks modifies post-creation). GovCloud: KMS required.

**Sources:** `terraform-databricks-sra/aws/tf/root_s3_bucket.tf`

---

### aws-account-log-delivery
`Account | AWS | Bootstrap`

**Purpose:** Creates the S3 bucket and IAM role for audit/billable usage log delivery, and configures the delivery itself.

**Resources:** `aws_s3_bucket` + versioning + public access block + policy, `aws_iam_role`, `time_sleep`, `databricks_mws_log_delivery`

**Provider requirements:** `aws`, `databricks.account`

**Inputs:** `databricks_account_id`, `aws_partition`, `resource_prefix`, `databricks_gov_shard`

**Outputs:** `log_delivery_configuration_id`, `bucket_name`, `role_arn`

**Notes:** Minimum tier: Premium. GovCloud: audit logging is required.

**Sources:** `terraform-databricks-sra/aws/tf/modules/databricks_account/audit_log_delivery/main.tf`

---

### aws-account-network-connectivity-config
`Account | AWS | Bootstrap`

**Purpose:** Creates a Databricks Network Connectivity Configuration (NCC) at account level for serverless compute private connectivity.

**Resources:** `databricks_mws_network_connectivity_config`

**Provider requirements:** `databricks.account`

**Inputs:** `region`, `databricks_account_id`, `resource_name`

**Outputs:** `network_connectivity_config_id`

**Notes:** Minimum tier: Premium. Max 10 NCCs per region.

**Sources:** `terraform-databricks-sra/aws/tf/modules/databricks_account/network_connectivity_configuration/main.tf`

---

### aws-account-network-vpc
`Account | AWS | Bootstrap`

**Purpose:** Creates the VPC, subnets (private, optional public, optional PrivateLink-dedicated), route tables, the Databricks-required security group, and registers the network with Databricks via `databricks_mws_networks`.

**Resources:** `aws_vpc`, `aws_subnet` (per configured tier), `aws_route_table`, `aws_route_table_association`, `aws_security_group` (Databricks default rules), `databricks_mws_networks`

**Provider requirements:** `aws`, `databricks.account`

**Inputs:** `vpc_cidr`, `private_subnet_cidrs`, optional `public_subnet_cidrs`, optional `privatelink_subnet_cidrs`, `azs`, `resource_prefix`, `databricks_account_id`, optional `vpc_endpoint_ids` (object with optional `rest_api_id` and `relay_id` for wiring into `databricks_mws_networks` when PrivateLink is in use)

**Outputs:** `vpc_id`, `private_subnet_ids`, `public_subnet_ids`, `privatelink_subnet_ids`, `security_group_id`, `databricks_network_id`, `private_route_table_ids`

**Notes:** Minimum tier: Premium. The VPC and its `databricks_mws_networks` registration are paired per Rule 1.4 — both are 1:1 with the abstraction "the network Databricks uses." `vpc_endpoint_ids` is an optional input populated by `aws-account-network-privatelink-endpoints` if used.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/aws/network-foundation/`

---

### aws-account-network-egress-internet
`Account | AWS | Bootstrap`

**Purpose:** Provides internet egress for private subnets via NAT gateway, with the corresponding Internet Gateway in the public subnets and the 0.0.0.0/0 routes from private route tables to the NAT.

**Resources:** `aws_internet_gateway`, `aws_eip`, `aws_nat_gateway`, `aws_route` (public→IGW), `aws_route` (private→NAT)

**Provider requirements:** `aws`

**Inputs:** `vpc_id`, `public_subnet_ids`, `private_route_table_ids`

**Outputs:** `nat_gateway_id`, `internet_gateway_id`, `nat_public_ip`

**Notes:** Minimum tier: Premium. Mutually exclusive with `aws-account-network-firewall` egress in the same VPC (both write 0.0.0.0/0 to the same route tables).

**Sources:** Pattern in `Databricks-Terraform-Monorepo/.../modules/aws/network-foundation/`

---

### aws-account-network-vpc-endpoints
`Account | AWS | Bootstrap`

**Purpose:** Creates the AWS VPC endpoints Databricks compute uses to reach AWS services without traversing the internet: S3 (gateway), STS and Kinesis (interface). Includes endpoint policies.

**Resources:** `aws_vpc_endpoint` (S3 gateway), `aws_vpc_endpoint` (STS interface), `aws_vpc_endpoint` (Kinesis interface); data sources for endpoint policy JSON

**Provider requirements:** `aws`

**Inputs:** `vpc_id`, `private_subnet_ids`, `security_group_id`, `private_route_table_ids` (for S3 gateway endpoint association), `region`

**Outputs:** `s3_endpoint_id`, `sts_endpoint_id`, `kinesis_endpoint_id`

**Notes:** Minimum tier: Premium. These endpoints target AWS services (S3, STS, Kinesis), distinct from `aws-account-network-privatelink-endpoints` which targets Databricks's own PrivateLink service.

**Sources:** `terraform-databricks-sra/aws/tf/privatelink.tf` (endpoint creation pattern)

---

### aws-account-network-privatelink-endpoints
`Account | AWS | Bootstrap`

**Purpose:** Creates the AWS PrivateLink interface endpoints to Databricks (workspace REST API + SCC relay + optional Service Direct), registers them with the Databricks account API, and creates the associated `databricks_mws_private_access_settings`.

**Resources:** `aws_vpc_endpoint` (workspace + relay + optional service-direct), `aws_security_group` (PrivateLink), `databricks_mws_vpc_endpoint` per registered endpoint, `databricks_mws_private_access_settings`

**Provider requirements:** `aws`, `databricks.account`

**Inputs:** `vpc_id`, `privatelink_subnet_ids`, `region`, `databricks_account_id`, `databricks_gov_shard`, `public_access_enabled`, optional `enable_service_direct`, optional `custom_service_attachment_uris` (override hardcoded region map)

**Outputs:** `workspace_vpc_endpoint_id`, `relay_vpc_endpoint_id`, `service_direct_vpc_endpoint_id`, `private_access_settings_id` — outputs designed to feed `aws-account-network-vpc`'s `vpc_endpoint_ids` input and `aws-account-workspace`'s `private_access_settings_id` input.

**Notes:** Minimum tier: Enterprise. Cloud-side + Databricks-side paired per Rule 1.4. GovCloud: distinct service attachment names per shard; Service Direct not available in GovCloud (`enable_service_direct = true` invalid for gov shards). Computed locals encode region+shard service attachment URIs.

**Sources:** `terraform-databricks-sra/aws/tf/privatelink.tf`, `Databricks-Terraform-Monorepo/.../modules/aws/network-privatelink/`

---

### aws-account-network-transit-gateway
`Account | AWS | Bootstrap`

**Purpose:** Creates a Transit Gateway and its attachments, with the route tables that move traffic between attached VPCs and shared services.

**Resources:** `aws_ec2_transit_gateway`, `aws_ec2_transit_gateway_vpc_attachment` (per attached VPC), `aws_ec2_transit_gateway_route_table`, route table associations and propagations

**Provider requirements:** `aws`

**Inputs:** `vpc_attachments` (map of name → object with `vpc_id`, `subnet_ids`), `tgw_asn`, `resource_prefix`

**Outputs:** `transit_gateway_id`, `attachment_ids` (map), `route_table_ids`

**Notes:** Minimum tier: Premium.

**Sources:** Not present in example repos.

---

### aws-account-network-firewall
`Account | AWS | Bootstrap`

**Purpose:** Creates AWS Network Firewall with policy and rule groups, plus the routes that send private subnet egress through the firewall instead of NAT.

**Resources:** `aws_networkfirewall_firewall`, `aws_networkfirewall_firewall_policy`, `aws_networkfirewall_rule_group` (multiple), `aws_route` (private→firewall endpoint)

**Provider requirements:** `aws`

**Inputs:** `vpc_id`, `firewall_subnet_ids`, `private_route_table_ids`, `policy_config` (object: stateful/stateless rule references)

**Outputs:** `firewall_id`, `firewall_endpoint_ips`, `firewall_arn`

**Notes:** Minimum tier: Premium. Mutually exclusive with `aws-account-network-egress-internet` for the same route tables.

**Sources:** Not present in example repos.

---

### aws-account-network-vpc-peering
`Account | AWS | Bootstrap`

**Purpose:** Creates a VPC peering connection with accepter and routes on both sides.

**Resources:** `aws_vpc_peering_connection`, `aws_vpc_peering_connection_accepter`, `aws_route` (both directions)

**Provider requirements:** `aws`

**Inputs:** `requester_vpc_id`, `accepter_vpc_id`, `requester_route_table_ids`, `accepter_route_table_ids`, `accepter_account_id` (for cross-account)

**Outputs:** `peering_connection_id`

**Notes:** Minimum tier: Premium. Alternative to TGW for direct VPC-to-VPC connectivity.

**Sources:** Not present in example repos.

---

### aws-account-workspace
`Account | AWS | Deployment`

**Purpose:** Creates a classic-compute Databricks workspace, wiring pre-created credentials, storage, network, and optional CMK/PrivateLink/NCC into one workspace.

**Resources:** `databricks_mws_workspaces`, `time_sleep` (DNS propagation), optional `databricks_mws_ncc_binding`, optional `databricks_workspace_network_option`

**Provider requirements:** `databricks.account`

**Inputs:** `workspace_name`, `region`, `databricks_gov_shard`, `credentials_id`, `storage_configuration_id`, `databricks_network_id`, optional `private_access_settings_id`, optional `managed_services_key_id`, optional `workspace_storage_key_id`, optional `network_connectivity_config_id`

**Outputs:** `workspace_id`, `workspace_url`, `workspace_host`, `deployment_name`

**Notes:** Minimum tier: Premium (Enterprise with PrivateLink or compliance profile). GovCloud: compliance profile auto-enabled; Nitro instance types only. Does NOT create credentials, storage, or network — paired modules do per Rule 1.4.

**Sources:** `terraform-databricks-sra/aws/tf/modules/databricks_account/workspace/main.tf`

---

### aws-account-workspace-serverless
`Account | AWS | Deployment`

**Purpose:** Creates a serverless-only Databricks workspace. No classic compute plane, no customer VPC, no credentials, no storage configuration required.

**Resources:** `databricks_mws_workspaces` (with `compute_mode = "SERVERLESS"`), optional `databricks_mws_customer_managed_keys` (managed services only), optional `databricks_mws_ncc_binding`

**Provider requirements:** `databricks.account`

**Inputs:** `workspace_name`, `region`, `databricks_gov_shard`, `databricks_account_id`, optional `managed_services_key_id`, optional `network_connectivity_config_id`

**Outputs:** `workspace_id`, `workspace_url`, `workspace_host`

**Notes:** Minimum tier: Premium. Distinct abstraction from classic `aws-account-workspace` — no network, no DBFS, no credentials.

**Sources:** Not present in example repos as a separate module.

---

## Account Layer — Azure (incl. Azure Government)

Azure Government parameterized at the `azurerm` provider level (`environment = "usgovernment"`) in root compositions.

---

### azure-account-encryption-keys
`Account | Azure | Bootstrap`

**Purpose:** Creates an Azure Key Vault with CMK keys for managed services, workspace storage, and managed disk encryption.

**Resources:** `azurerm_key_vault`, `azurerm_key_vault_key` ×3, `azurerm_key_vault_access_policy`, optional `azurerm_private_endpoint` for Key Vault

**Provider requirements:** `azurerm`

**Inputs:** `resource_group_name`, `location`, `databricks_service_principal_object_id`, `azure_client_id`, optional VNet for PE

**Outputs:** `key_vault_id`, `managed_services_key_id`, `workspace_storage_key_id`, `managed_disk_key_id`

**Notes:** Minimum tier: Premium. Azure Gov / IL5: CMK mandatory. Premium SKU required for HSM-backed keys. Unlike AWS, no Databricks-side registration here — keys flow directly into `azurerm_databricks_workspace` arguments and the post-creation `azurerm_databricks_workspace_root_dbfs_customer_managed_key` resource (handled in `azure-account-workspace`).

**Sources:** `Databricks-Terraform-Monorepo/.../modules/azure/components/cmek-keys/`, `terraform-databricks-sra/azure/tf/modules/hub/keyvault.tf`

---

### azure-account-workspace-storage
`Account | Azure | Deployment`

**Purpose:** Creates ADLS Gen2 storage account and container for UC metastore storage or workspace root storage.

**Resources:** `azurerm_storage_account`, `azurerm_storage_container`

**Provider requirements:** `azurerm`

**Inputs:** `resource_group_name`, `location`, `resource_prefix`, optional `kms_key_id`

**Outputs:** `storage_account_name`, `storage_account_id`, `container_name`, `dfs_endpoint`

**Notes:** Minimum tier: Premium. Azure Gov / IL5: CMK required.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/azure/components/adls-storage/`

---

### azure-account-network-connectivity-config
`Account | Azure | Bootstrap`

**Purpose:** Creates a Databricks NCC at account level for Azure serverless private connectivity, with optional account network policy.

**Resources:** `databricks_mws_network_connectivity_config`, optional `databricks_account_network_policy`

**Provider requirements:** `databricks.account`

**Inputs:** `region`, `databricks_account_id`, `resource_name`, optional `allowed_internet_destinations`

**Outputs:** `network_connectivity_config_id`, optional `network_policy_id`

**Notes:** Minimum tier: Premium. Max 10 NCCs per region.

**Sources:** `terraform-databricks-sra/azure/tf/modules/hub/serverless.tf`

---

### azure-account-network-vnet
`Account | Azure | Bootstrap`

**Purpose:** Creates the VNet and subnets used for Databricks VNet injection (host + container required; optional PE subnet), with NSGs and associations.

**Resources:** `azurerm_virtual_network`, `azurerm_subnet` (host, container, optional PE), `azurerm_network_security_group`, `azurerm_subnet_network_security_group_association`

**Provider requirements:** `azurerm`

**Inputs:** `resource_group_name`, `location`, `vnet_cidr`, `host_subnet_cidr`, `container_subnet_cidr`, optional `pe_subnet_cidr`

**Outputs:** `vnet_id`, `host_subnet_id`, `host_subnet_name`, `container_subnet_id`, `container_subnet_name`, `pe_subnet_id`

**Notes:** Minimum tier: Premium. Azure has no `databricks_mws_networks` equivalent — the workspace module consumes VNet inputs directly via `custom_parameters`.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/azure/network-foundation/`

---

### azure-account-network-private-endpoints
`Account | Azure | Bootstrap`

**Purpose:** Creates Azure Private Endpoints to Databricks (back-end `databricks_ui_api`, optional front-end, optional `browser_authentication`) and the private DNS zones + VNet links that resolve the workspace URL to the PE IP.

**Resources:** `azurerm_private_endpoint` (back-end + optional front-end + optional browser-auth), `azurerm_private_dns_zone` (`privatelink.azuredatabricks.net`), `azurerm_private_dns_zone_virtual_network_link`

**Provider requirements:** `azurerm`

**Inputs:** `resource_group_name`, `location`, `workspace_resource_id`, `vnet_id` (for DNS link), `pe_subnet_id`, optional `enable_front_end`, optional `enable_browser_auth`, optional hub VNet inputs (for cross-VNet DNS link)

**Outputs:** `back_end_pe_id`, `front_end_pe_id`, `browser_auth_pe_id`, `private_dns_zone_id`

**Notes:** Minimum tier: Premium.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/azure/network-privatelink/`

---

### azure-account-network-firewall
`Account | Azure | Bootstrap`

**Purpose:** Creates Azure Firewall with policy, IP groups, and the route tables that direct VNet egress through the firewall.

**Resources:** `azurerm_firewall`, `azurerm_firewall_policy`, `azurerm_firewall_policy_rule_collection_group`, `azurerm_ip_group`, `azurerm_public_ip`, `azurerm_route_table`, `azurerm_route` (forced tunnel to firewall)

**Provider requirements:** `azurerm`

**Inputs:** `resource_group_name`, `location`, `firewall_subnet_id`, `spoke_route_table_ids` (forced routing), `allowed_spoke_cidr_ranges` (for IP groups), `service_tag_rules` (Databricks region-specific)

**Outputs:** `firewall_id`, `firewall_private_ip`, `route_table_id`

**Notes:** Minimum tier: Premium. Rule collections use Databricks service tags per region (e.g., `Storage.EastUs`).

**Sources:** `terraform-databricks-sra/azure/tf/modules/hub/firewall.tf`

---

### azure-account-network-vnet-peering
`Account | Azure | Bootstrap`

**Purpose:** Creates VNet peering in both directions between two VNets.

**Resources:** `azurerm_virtual_network_peering` ×2 (one per direction)

**Provider requirements:** `azurerm`

**Inputs:** `local_vnet_id`, `remote_vnet_id`, `local_resource_group_name`, `remote_resource_group_name`, peering options

**Outputs:** `local_peering_id`, `remote_peering_id`

**Notes:** Minimum tier: Premium.

**Sources:** Not present in example repos.

---

### azure-account-workspace
`Account | Azure | Deployment`

**Purpose:** Creates an Azure Databricks workspace with optional VNet injection, CMK, compliance profile, and private connectivity.

**Resources:** `azurerm_databricks_workspace`, optional `azurerm_databricks_workspace_root_dbfs_customer_managed_key` (post-creation), optional `azapi_update_resource` (compliance standards workaround)

**Provider requirements:** `azurerm`, `azapi`

**Inputs:** `resource_group_name`, `location`, `resource_prefix`, optional VNet/subnet inputs (`host_subnet_name`, `container_subnet_name`, `virtual_network_id`), optional CMK key IDs, optional compliance settings, optional `public_network_access_enabled`

**Outputs:** `workspace_id`, `workspace_url`, `workspace_resource_id`

**Notes:** Minimum tier: Premium. `sku = "premium"` for Premium features. Azure Gov / IL5 requires provider `environment = "usgovernment"`. Non-HIPAA/PCI compliance standards require `azapi_update_resource` with `ignore_changes` on the `azurerm` resource per Rule 3.2 Databricks.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/azure/base-workspace/`, `terraform-databricks-sra/azure/tf/modules/workspace/`

---

### azure-account-workspace-serverless
`Account | Azure | Deployment`

**Purpose:** Creates an Azure Databricks workspace without VNet injection, intended for serverless compute only.

**Resources:** `azurerm_databricks_workspace` (no `custom_parameters` for VNet)

**Provider requirements:** `azurerm`

**Inputs:** `resource_group_name`, `location`, `resource_prefix`, optional CMK key IDs

**Outputs:** `workspace_id`, `workspace_url`, `workspace_resource_id`

**Notes:** Minimum tier: Premium. Distinct from classic `azure-account-workspace` by absence of VNet injection.

**Sources:** Not present in example repos as a separate module.

---

## Account Layer — GCP

---

### gcp-account-provisioning-service-account
`Account | GCP | Bootstrap`

**Purpose:** Creates a GCP service account with a custom IAM role (compute, KMS, GKE, Shared VPC permissions) for Databricks workspace provisioning, and registers it as a Databricks account admin.

**Resources:** `google_service_account`, `google_project_iam_custom_role`, `google_project_iam_member`, `google_service_account_iam_member`, `databricks_user`, `databricks_user_role`

**Provider requirements:** `google`, `databricks.account`

**Inputs:** `project_id`, `databricks_account_id`, `delegate_emails`, `resource_prefix`

**Outputs:** `service_account_email`, `custom_role_id`

**Notes:** Minimum tier: Premium.

**Sources:** `terraform-databricks-sra/gcp/modules/service_account/`, `terraform-databricks-sra/gcp/modules/make_sa_dbx_admin/`

---

### gcp-account-workspace-storage
`Account | GCP | Deployment`

**Purpose:** Creates a GCS bucket for workspace root storage with Databricks service account IAM bindings and registers it as a Databricks storage configuration.

**Resources:** `google_storage_bucket`, `google_storage_bucket_iam_member` (objectAdmin, legacyBucketReader), `databricks_mws_storage_configurations`

**Provider requirements:** `google`, `databricks.account`

**Inputs:** `project_id`, `region`, `resource_prefix`, `databricks_service_account_email`, `databricks_account_id`, optional `kms_key_name`

**Outputs:** `storage_configuration_id`, `bucket_name`, `bucket_url`

**Notes:** Minimum tier: Premium.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/gcp/components/root-storage/`

---

### gcp-account-network-vpc
`Account | GCP | Bootstrap`

**Purpose:** Creates the VPC, subnetwork (with secondary IP ranges for GKE pods/services), firewall rules, and registers the network with Databricks via `databricks_mws_networks`.

**Resources:** `google_compute_network`, `google_compute_subnetwork`, `google_compute_firewall` (Databricks-required rules), `databricks_mws_networks`

**Provider requirements:** `google`, `databricks.account`

**Inputs:** `project_id`, `region`, `network_cidr`, `subnetwork_cidr`, `pod_secondary_range_cidr`, `service_secondary_range_cidr`, `databricks_account_id`, optional `vpc_endpoint_ids` (for PSC wiring into `databricks_mws_networks`)

**Outputs:** `network_self_link`, `subnetwork_self_link`, `databricks_network_id`, secondary range names

**Notes:** Minimum tier: Premium. Paired per Rule 1.4.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/gcp/network-foundation/`

---

### gcp-account-network-cloud-nat
`Account | GCP | Bootstrap`

**Purpose:** Provides internet egress for private subnets via Cloud Router and Cloud NAT.

**Resources:** `google_compute_router`, `google_compute_router_nat`

**Provider requirements:** `google`

**Inputs:** `project_id`, `region`, `network_self_link`, `subnetwork_self_link`, `resource_prefix`

**Outputs:** `router_id`, `nat_id`

**Notes:** Minimum tier: Premium.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/gcp/network-foundation/`

---

### gcp-account-network-psc-endpoints
`Account | GCP | Deployment`

**Purpose:** Creates Private Service Connect forwarding rules to Databricks (workspace + relay), the private DNS zones that resolve workspace URLs to PSC IPs, and registers the endpoints with the Databricks account API.

**Resources:** `google_compute_address` ×2, `google_compute_forwarding_rule` ×2, `google_dns_managed_zone` (`gcp.databricks.com`), `google_dns_record_set` ×3, `databricks_mws_vpc_endpoint` ×2, `databricks_mws_private_access_settings`

**Provider requirements:** `google`, `databricks.account`

**Inputs:** `project_id`, `region`, `network_self_link`, `psc_subnet_self_link`, `databricks_account_id`, optional custom service attachment URIs

**Outputs:** `workspace_psc_endpoint_id`, `relay_psc_endpoint_id`, `private_access_settings_id`

**Notes:** Minimum tier: Enterprise. Paired per Rule 1.4. Service attachment URIs per region are computed locals. PSC endpoints can be shared across workspaces in same region/VPC.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/gcp/network-privatelink/`

---

### gcp-account-network-cloud-ngfw
`Account | GCP | Bootstrap`

**Purpose:** Creates Cloud NGFW security profiles, security profile groups, and firewall endpoints for VPC egress inspection.

**Resources:** Cloud NGFW security profile + group + association + firewall endpoint (resources vary by provider version)

**Provider requirements:** `google`, `google-beta` (some Cloud NGFW resources are beta)

**Inputs:** `project_id`, `region`, `network_self_link`, policy config

**Outputs:** `security_profile_group_id`, `firewall_endpoint_id`

**Notes:** Minimum tier: Premium.

**Sources:** Not present in example repos.

---

### gcp-account-network-shared-vpc
`Account | GCP | Bootstrap`

**Purpose:** Configures a host project as a Shared VPC host and attaches service projects.

**Resources:** `google_compute_shared_vpc_host_project`, `google_compute_shared_vpc_service_project` per attachment, optional `google_compute_subnetwork_iam_member` for service-project subnet access

**Provider requirements:** `google`

**Inputs:** `host_project_id`, `service_project_ids`, optional subnet IAM grants

**Outputs:** `host_project_attachment_id`, attachment IDs per service project

**Notes:** Minimum tier: Premium.

**Sources:** Not present in example repos.

---

### gcp-account-workspace
`Account | GCP | Deployment`

**Purpose:** Creates a classic-compute Databricks workspace on GCP, wiring pre-created network and storage configuration, optional PSC, and optional CMEK.

**Resources:** `databricks_mws_workspaces`, optional `databricks_mws_customer_managed_keys`

**Provider requirements:** `databricks.account`

**Inputs:** `project_id`, `region`, `resource_prefix`, `databricks_network_id`, `storage_configuration_id`, optional `private_access_settings_id`, optional CMK key IDs

**Outputs:** `workspace_id`, `workspace_url`

**Notes:** Minimum tier: Premium.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/gcp/base-workspace/`

---

### gcp-account-workspace-serverless
`Account | GCP | Deployment`

**Purpose:** Creates a serverless-only Databricks workspace on GCP. No network, no classic compute plane.

**Resources:** `databricks_mws_workspaces` with `compute_mode = "SERVERLESS"`

**Provider requirements:** `databricks.account`

**Inputs:** `project_id`, `region`, `resource_prefix`, optional `managed_services_key_id`

**Outputs:** `workspace_id`, `workspace_url`

**Notes:** Minimum tier: Premium. Distinct abstraction from classic `gcp-account-workspace`.

**Sources:** Not present in example repos as a separate module.

---

## Unity Catalog Layer

UC modules use `configuration_aliases` for `databricks.account` and `databricks.workspace`. Cloud storage is an input (created by account-layer modules).

---

### aws-uc-storage-credential
`Unity Catalog | AWS | Deployment`

**Purpose:** Creates the AWS IAM role for Unity Catalog storage access and registers it as a `databricks_storage_credential`.

**Resources:** `aws_iam_role`, `aws_iam_role_policy`, `time_sleep`, `databricks_storage_credential`

**Provider requirements:** `aws`, `databricks.workspace` (or `databricks.account`)

**Inputs:** `credential_name`, `bucket_arn`, `aws_partition`, `databricks_account_id`, `databricks_gov_shard`

**Outputs:** `storage_credential_id`, `iam_role_arn`

**Notes:** Minimum tier: Premium. Paired per Rule 1.4. GovCloud: UC cross-account ARN differs per shard.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/aws/account-uc-setup/`, `terraform-databricks-sra/aws/tf/modules/databricks_workspace/unity_catalog_catalog_creation/`

---

### azure-uc-storage-credential
`Unity Catalog | Azure | Deployment`

**Purpose:** Creates an Azure Databricks Access Connector (managed identity), assigns it Storage Blob Data Contributor on a target storage account, and registers it as a `databricks_storage_credential` for Unity Catalog.

**Resources:** `azurerm_databricks_access_connector`, `azurerm_role_assignment`, `databricks_storage_credential`

**Provider requirements:** `azurerm`, `databricks` (workspace or account, depending on credential scope)

**Inputs:** `resource_group_name`, `location`, `storage_account_id`, `credential_name`

**Outputs:** `access_connector_id`, `access_connector_principal_id`, `storage_credential_id`

**Notes:** Minimum tier: Premium. Cloud-side + Databricks-side paired per Rule 1.4. The Access Connector is the Azure UC credential mechanism — combining it with `databricks_storage_credential` is the indivisible pairing.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/azure/components/access-connector/`

---

### gcp-uc-storage-credential
`Unity Catalog | GCP | Deployment`

**Purpose:** Configures a Databricks GCP service account for UC storage access and registers it as a storage credential.

**Resources:** `databricks_storage_credential` (with `databricks_gcp_service_account` block), `google_storage_bucket_iam_member`

**Provider requirements:** `google`, `databricks.workspace`

**Inputs:** `credential_name`, `bucket_name`

**Outputs:** `storage_credential_id`, `databricks_service_account_email`

**Notes:** Minimum tier: Premium.

**Sources:** `terraform-databricks-examples/modules/gcp-unity-catalog/databricks-cloud-resources.tf`

---

### dbx-uc-metastore
`Unity Catalog | Agnostic | Deployment`

**Purpose:** Creates a Unity Catalog metastore and sets its default data access credential.

**Resources:** `databricks_metastore`, `databricks_metastore_data_access`

**Provider requirements:** `databricks.account`

**Inputs:** `metastore_name`, `region`, `storage_root_url`, `default_storage_credential_id`, `owner_group`

**Outputs:** `metastore_id`, `metastore_name`

**Notes:** Minimum tier: Premium. One metastore per account per region.

**Sources:** Synthesized from `Databricks-Terraform-Monorepo/.../modules/{aws,azure,gcp}/account-uc-setup/`, `terraform-databricks-sra/aws/tf/modules/databricks_account/unity_catalog_metastore_creation/`

---

### dbx-uc-metastore-assignment
`Unity Catalog | Agnostic | Bootstrap`

**Purpose:** Assigns a metastore to one or more workspaces and optionally sets a default catalog per workspace.

**Resources:** `databricks_metastore_assignment` (via `for_each`), optional `databricks_default_namespace_setting`

**Provider requirements:** `databricks.account`

**Inputs:** `metastore_id`, `workspace_assignments` (map: `workspace_id` → optional `default_catalog_name`)

**Outputs:** `assignment_ids`

**Notes:** Minimum tier: Premium.

**Sources:** `terraform-databricks-sra/aws/tf/modules/databricks_account/unity_catalog_metastore_assignment/`

---

### dbx-uc-external-location
`Unity Catalog | Agnostic | Bootstrap`

**Purpose:** Registers cloud storage paths as Unity Catalog external locations.

**Resources:** `databricks_external_location` (via `for_each`), optional `databricks_grants`

**Provider requirements:** `databricks.workspace`

**Inputs:** `locations` (map: name → url + storage_credential_id), optional grants per location

**Outputs:** `external_location_ids`

**Notes:** Minimum tier: Premium.

**Sources:** `terraform-databricks-sra/aws/tf/modules/databricks_workspace/unity_catalog_catalog_creation/`

---

### dbx-uc-catalog
`Unity Catalog | Agnostic | Operational`

**Purpose:** Creates UC catalogs with optional storage root, isolation mode, and grants.

**Resources:** `databricks_catalog` (via `for_each`), optional `databricks_grants` per catalog

**Provider requirements:** `databricks.workspace`

**Inputs:** `metastore_id`, `catalogs` (map of name → config)

**Outputs:** `catalog_ids`

**Notes:** Minimum tier: Premium.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/shared/workspace-uc-binding/`, `terraform-databricks-examples/examples/aws-workspace-uc-simple/`

---

### dbx-uc-schema
`Unity Catalog | Agnostic | Operational`

**Purpose:** Creates schemas within a catalog with optional managed location and grants.

**Resources:** `databricks_schema` (via `for_each`), optional `databricks_grants` per schema

**Provider requirements:** `databricks.workspace`

**Inputs:** `catalog_name`, `schemas` (map of name → config)

**Outputs:** `schema_ids`

**Notes:** Minimum tier: Premium.

**Sources:** `terraform-databricks-examples/examples/adb-unity-catalog-basic-demo/modules/metastore-and-users/`

---

## Workspace Layer

All workspace-layer modules use `databricks.workspace` provider only. Cloud-agnostic by Rule 1.2.

---

### dbx-workspace-identity
`Workspace | Agnostic | Bootstrap / Operational`

**Purpose:** Assigns account-level principals (groups, service principals, users) to a workspace with workspace roles (ADMIN, USER).

**Resources:** `databricks_mws_permission_assignment` (via `for_each`), `time_sleep` (20s post-workspace)

**Provider requirements:** `databricks.account`

**Inputs:** `workspace_id`, `assignments` (map: principal_id → list of roles)

**Outputs:** `assignment_ids`

**Notes:** Minimum tier: Premium. Identity model: this module manages references only — does NOT create groups/users (those come from native creation OR SCIM/AIM IdP). `ignore_changes = [principal_id]` per Rule 3.2 Databricks.

**Sources:** `terraform-databricks-sra/aws/tf/modules/databricks_account/user_assignment/`

---

### dbx-workspace-cluster-policies
`Workspace | Agnostic | Deployment`

**Purpose:** Defines cluster policy governance constraints for a workspace and assigns access to those policies.

**Resources:** `databricks_cluster_policy` (via `for_each`), `databricks_permissions` per policy

**Provider requirements:** `databricks.workspace`

**Inputs:** `policies` (map of name → definition or policy_family+overrides), `policy_assignments` (map: policy → principals + access level)

**Outputs:** `policy_ids`

**Notes:** Minimum tier: Premium.

**Sources:** `terraform-databricks-examples/modules/cluster-policy-from-policy-family/`

---

### dbx-workspace-ip-access-list
`Workspace | Agnostic | Deployment`

**Purpose:** Enables and configures IP-based network access control for a workspace.

**Resources:** `databricks_workspace_conf` (`enableIpAccessLists = true`), `databricks_ip_access_list`

**Provider requirements:** `databricks.workspace`

**Inputs:** `allow_list` (CIDR list), optional `block_list`

**Outputs:** `access_list_id`

**Notes:** Minimum tier: Premium (Azure/GCP) / Enterprise (AWS). Without the workspace_conf flag, list is silently not enforced.

**Sources:** `terraform-databricks-examples/examples/aws-workspace-config/modules/ip_access_list/`

---

### dbx-workspace-secret-scope
`Workspace | Agnostic | Deployment`

**Purpose:** Creates secret scopes (structure and ACLs only — not values).

**Resources:** `databricks_secret_scope` (via `for_each`)

**Provider requirements:** `databricks.workspace`

**Inputs:** `scopes` (map of name → config, including optional `keyvault_metadata` for Azure Key Vault-backed)

**Outputs:** `scope_names`

**Notes:** Minimum tier: Premium. Secret VALUES managed externally — not by this module.

**Sources:** `terraform-databricks-examples/modules/adb-overwatch-mws-config/`

---

### dbx-workspace-compliance-settings
`Workspace | Agnostic | Bootstrap`

**Purpose:** Applies workspace-level security hardening (compliance security profile, enhanced monitoring, auto cluster updates, legacy access/DBFS disablement).

**Resources:** `databricks_compliance_security_profile_workspace_setting`, `databricks_enhanced_security_monitoring_workspace_setting`, `databricks_automatic_cluster_update_workspace_setting`, `databricks_disable_legacy_access_setting`, `databricks_disable_legacy_dbfs_setting`

**Provider requirements:** `databricks.workspace`

**Inputs:** `compliance_standards`, feature flags

**Outputs:** None

**Notes:** Minimum tier: Enterprise (compliance + monitoring + auto-updates); Premium for legacy settings. Settings are immutable post-workspace-creation. GovCloud: compliance profile auto-enabled; this module is a no-op there (use `precondition` to skip). Azure non-HIPAA/PCI compliance handled in `azure-account-workspace` via `azapi_update_resource`.

**Sources:** `terraform-databricks-sra/aws/tf/modules/databricks_workspace/compliance_security_profile/`, `terraform-databricks-sra/aws/tf/modules/databricks_workspace/disable_legacy_settings/`

---

### dbx-workspace-network-serverless
`Workspace | Agnostic | Bootstrap`

**Purpose:** Binds an NCC to a workspace for serverless compute private connectivity, with cloud-specific private endpoint rules.

**Resources:** `databricks_mws_ncc_binding`, `databricks_mws_ncc_private_endpoint_rule` (via `for_each`), optional `databricks_workspace_network_option`

**Provider requirements:** `databricks.account` + `databricks.workspace`

**Inputs:** `workspace_id`, `network_connectivity_config_id`, `private_endpoint_rules` (list of cloud resource IDs + types), optional `network_policy_id`

**Outputs:** `ncc_binding_id`

**Notes:** Minimum tier: Premium. Cloud-specific PE rule types: AWS (`AWS_S3_BUCKET`, etc.), Azure (`AZURE_STORAGE_ACCOUNT` with `blob` + `dfs` subresources), GCP (`GCP_GCS_BUCKET`, etc.). Max 50 workspaces per NCC.

**Sources:** `Databricks-Terraform-Monorepo/.../modules/shared/network-serverless-security/`

---

## Modules added from gap analysis (2026-06-16)

These modules were identified through cross-repo comparison (terraform-databricks-examples, Databricks-Terraform-Monorepo, terraform-databricks-sra, terraform-provider-databricks) and added to the catalog:

### dbx-workspace-sql-warehouse
`Workspace | Agnostic | Operational`

**Purpose:** Creates a Databricks SQL warehouse with sizing, spot policy, channel, and permissions.

**Resources:** `databricks_sql_endpoint`, `databricks_permissions`

**Provider requirements:** `databricks.workspace`

**Notes:** Minimum tier: Premium. Source: identified as gap in terraform-databricks-examples comparison (department-clusters module uses this resource without standalone abstraction).

---

### aws-workspace-restrictive-root-bucket
`Workspace | AWS | Bootstrap`

**Purpose:** Applies a least-privilege S3 bucket policy to a workspace's root storage bucket AFTER workspace creation. Scopes writes to workspace-ID-specific paths, enforces principal tag conditions, requires SSL.

**Resources:** `aws_s3_bucket_policy`

**Provider requirements:** `aws`

**Notes:** Minimum tier: Premium. Source: terraform-databricks-sra `restrictive_root_bucket` module. Security hardening that can only happen post-workspace (workspace ID needed for path scoping).

---

### dbx-account-network-policy
`Account | Agnostic | Bootstrap`

**Purpose:** Creates an account-level Databricks network policy controlling serverless compute egress posture.

**Resources:** `databricks_account_network_policy`

**Provider requirements:** `databricks.account`

**Notes:** Minimum tier: Premium. Source: terraform-databricks-sra `network_policy` module. Complements NCC modules (NCC = connectivity; this = restriction).

---

### aws-account-network-serverless-privatelink
`Account | AWS | Bootstrap`

**Purpose:** Creates the customer-side AWS infrastructure (NLB + endpoint service) that enables Databricks serverless compute to reach a customer resource (RDS, Redshift, etc.) over PrivateLink.

**Resources:** `aws_lb`, `aws_lb_target_group`, `aws_lb_listener`, `aws_vpc_endpoint_service`, `aws_vpc_endpoint_service_allowed_principal`, `aws_security_group`

**Provider requirements:** `aws`

**Notes:** Minimum tier: Premium. Source: terraform-databricks-examples `aws-serverless-privatelink-to-cloud-service` module. Pairs with `dbx-workspace-network-serverless` which handles the Databricks side (NCC PE rule).

---

### gcp-account-vpc-service-controls
`Account | GCP | Bootstrap`

**Purpose:** Creates a VPC Service Controls perimeter restricting data egress at the GCP project level.

**Resources:** `google_access_context_manager_service_perimeter`, `google_access_context_manager_access_level`

**Provider requirements:** `google`

**Notes:** Minimum tier: Premium. Source: Databricks-Terraform-Monorepo `gcp/vpc-service-controls`. GCP equivalent of AWS Network Firewall / Azure Firewall for egress isolation.

---

## Resolutions

- Topology variants (simple, privatelink, closed, inspection, hub-spoke) are compositions of primitives at a layer above modules. The module catalog lists primitives.
- Serverless workspaces are a separate abstraction from classic workspaces — distinct module per cloud (`*-account-workspace-serverless`).
- Module naming follows `<cloud>-<surface>-<name>` convention; `dbx` denotes cloud-agnostic.
- Azure UC storage credential is `azure-uc-storage-credential` (Access Connector + `databricks_storage_credential` paired per Rule 1.4).
- UC storage credential modules are classified under the Unity Catalog surface across all clouds, even where the underlying cloud-side resource is account-level (AWS IAM role; Azure Access Connector; GCP service account). The classification reflects the abstraction's function, not the underlying resources' provider surface.
- `dbx-workspace-team` (group + cluster + SQL endpoint + policy) is a composition, not a primitive. Deferred to blueprint/composition layer.

---

## Remaining gaps (not yet built)

- `dbx-workspace-lakebase` — Lakebase (PostgreSQL federation) module. 7 provider resources (v1.102-v1.113). Deferred until GA stabilization.
- Azure / GCP log delivery (only AWS modularized)
- Account-level groups module (only relevant for native identity; absent in repos that assume SCIM/AIM)
- Key rotation management (no module handles CMK rotation)
- AIM / SCIM integration configuration (no module configures SCIM token generation or AIM enablement)
