# azure-account-workspace

Creates an Azure Databricks workspace with optional VNet injection, customer-managed keys (managed services, managed disk, root DBFS), compliance security profile, and private connectivity settings.

## What this module abstracts

"The workspace Databricks runs on Azure" — the full workspace provisioning surface in one module. The `azurerm_databricks_workspace` resource plus its two companion post-creation resources (`azurerm_databricks_workspace_root_dbfs_customer_managed_key` and the `azapi_update_resource` compliance-standards workaround) always belong together: callers that want a workspace get all three in a single module call.

## When to use

- You are provisioning a new Azure-hosted Databricks workspace (commercial or Azure Government).
- You want VNet injection, CMK, and/or compliance profile wired together in one module call.
- You need extended compliance standards (HITRUST, IRAP_PROTECTED, etc.) that the `azurerm` provider does not support natively.

## When NOT to use

- You already have a workspace and only want to assign a metastore or configure Unity Catalog — use the `azure-account-unity-catalog` module instead.
- You need a serverless-only workspace without VNet injection — use `azure-account-workspace-serverless`.
- Your workspace was provisioned outside Terraform — import it at the root composition instead.

## Minimum platform tier

**Premium.** Set `sku = "premium"` (the default). The compliance security profile and enhanced security monitoring require the **Enhanced Security and Compliance add-on** (Enterprise-level). The `azurerm` Terraform provider does not enforce tier at plan time; a lower-tier workspace will fail at apply time.

## Azure Government parameterization

Azure Government is a provider-level concern, not a module-level input. At the root composition, configure the `azurerm` provider with `environment = "usgovernment"`. This module does not need a separate input for Azure Gov; the provider handles all endpoint routing. On Azure Gov / IL5 workspaces the compliance security profile is auto-enabled; the `compliance_security_profile_enabled` variable should be set to `true` to reflect this in state.

## Provider configuration

This module uses only `azurerm` and `azapi` providers. No `configuration_aliases` are needed (neither provider surfaces a Databricks API; this is pure Azure control-plane). The Databricks workspace-scoped provider is configured in the root composition after the workspace URL is known, using `output.workspace_url` from this module.

## VNet injection

Set `virtual_network_id`, `host_subnet_name`, `container_subnet_name`, and both NSG association IDs together. When `virtual_network_id` is null, a managed VNet is created by Azure. Use `no_public_ip = true` (SCC) for production workspaces.

## Customer-managed keys

Three independent CMK planes are supported:

| Plane | Variable |
|---|---|
| Managed services (notebooks, artifacts) | `managed_services_cmk_key_vault_key_id` + `customer_managed_key_enabled = true` |
| Managed disks (cluster VMs) | `managed_disk_cmk_key_vault_key_id` |
| Root DBFS | `root_dbfs_cmk_key_vault_key_id` |

Root DBFS CMK is applied as a post-creation step via `azurerm_databricks_workspace_root_dbfs_customer_managed_key`. The workspace's managed identity (`output.storage_account_identity`) must be granted Key Vault access at the root composition before this resource is applied.

## Compliance security profile and extended standards

The `azurerm` provider supports only `HIPAA`, `PCI_DSS`, and `NONE` as `compliance_security_profile_standards`. For `HITRUST`, `IRAP_PROTECTED`, `UK_CYBER_ESSENTIALS_PLUS`, or `CANADA_PROTECTED_B`, pass those values in `extended_compliance_standards`. The module applies them via `azapi_update_resource` (ARM REST API patch), and `ignore_changes` on the `azurerm` workspace prevents Terraform from reverting them on subsequent plans. This is a sanctioned `ignore_changes` use per DATABRICKS_RULES.md Rule 3.2.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.76 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | >= 1.9 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.76 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azapi_update_resource.compliance_standards](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) | resource |
| [azurerm_databricks_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace) | resource |
| [azurerm_databricks_workspace_root_dbfs_customer_managed_key.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace_root_dbfs_customer_managed_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_connector_id"></a> [access\_connector\_id](#input\_access\_connector\_id) | Resource ID of the Azure Databricks Access Connector. Required when default\_storage\_firewall\_enabled = true. | `string` | `null` | no |
| <a name="input_automatic_cluster_update_enabled"></a> [automatic\_cluster\_update\_enabled](#input\_automatic\_cluster\_update\_enabled) | Enable automatic cluster update. Part of the Enhanced Security and Compliance add-on. Requires compliance\_security\_profile\_enabled = true when the compliance profile is in use. | `bool` | `false` | no |
| <a name="input_compliance_security_profile_enabled"></a> [compliance\_security\_profile\_enabled](#input\_compliance\_security\_profile\_enabled) | Enable the Compliance Security Profile. Permanent for a workspace — cannot be disabled once enabled. Requires the Enhanced Security and Compliance add-on and premium SKU. | `bool` | `false` | no |
| <a name="input_compliance_security_profile_standards"></a> [compliance\_security\_profile\_standards](#input\_compliance\_security\_profile\_standards) | List of compliance standards to enable. Valid values via azurerm: "HIPAA", "PCI\_DSS", "NONE". Other standards (HITRUST, IRAP\_PROTECTED, UK\_CYBER\_ESSENTIALS\_PLUS, CANADA\_PROTECTED\_B) require the azapi workaround (see extended\_compliance\_standards). Only meaningful when compliance\_security\_profile\_enabled = true. | `list(string)` | `[]` | no |
| <a name="input_container_subnet_name"></a> [container\_subnet\_name](#input\_container\_subnet\_name) | Name of the private (container) subnet within the VNet for VNet injection. Required when virtual\_network\_id is set. | `string` | `null` | no |
| <a name="input_customer_managed_key_enabled"></a> [customer\_managed\_key\_enabled](#input\_customer\_managed\_key\_enabled) | Enable customer-managed key for managed services encryption. Requires premium SKU and managed\_services\_cmk\_key\_vault\_key\_id. | `bool` | `false` | no |
| <a name="input_default_storage_firewall_enabled"></a> [default\_storage\_firewall\_enabled](#input\_default\_storage\_firewall\_enabled) | Disallow public access to the default storage account. When true, access\_connector\_id must also be set. | `bool` | `false` | no |
| <a name="input_enhanced_security_monitoring_enabled"></a> [enhanced\_security\_monitoring\_enabled](#input\_enhanced\_security\_monitoring\_enabled) | Enable enhanced security monitoring. Part of the Enhanced Security and Compliance add-on. | `bool` | `false` | no |
| <a name="input_extended_compliance_standards"></a> [extended\_compliance\_standards](#input\_extended\_compliance\_standards) | Additional compliance standards not supported by the azurerm provider: "HITRUST", "IRAP\_PROTECTED", "UK\_CYBER\_ESSENTIALS\_PLUS", "CANADA\_PROTECTED\_B". Applied via azapi\_update\_resource post-creation. Only meaningful when compliance\_security\_profile\_enabled = true. | `list(string)` | `[]` | no |
| <a name="input_host_subnet_name"></a> [host\_subnet\_name](#input\_host\_subnet\_name) | Name of the public (host) subnet within the VNet for VNet injection. Required when virtual\_network\_id is set. | `string` | `null` | no |
| <a name="input_infrastructure_encryption_enabled"></a> [infrastructure\_encryption\_enabled](#input\_infrastructure\_encryption\_enabled) | Enable a secondary layer of encryption for workspace data at rest. Requires premium SKU. Immutable after workspace creation. | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the workspace (e.g., "eastus", "westeurope"). Must match the resource group region. | `string` | n/a | yes |
| <a name="input_managed_disk_cmk_key_vault_key_id"></a> [managed\_disk\_cmk\_key\_vault\_key\_id](#input\_managed\_disk\_cmk\_key\_vault\_key\_id) | Key Vault key ID for managed disk encryption. Requires premium SKU. | `string` | `null` | no |
| <a name="input_managed_disk_cmk_rotation_to_latest_version_enabled"></a> [managed\_disk\_cmk\_rotation\_to\_latest\_version\_enabled](#input\_managed\_disk\_cmk\_rotation\_to\_latest\_version\_enabled) | Automatically rotate managed disk CMK to the latest key version. Only relevant when managed\_disk\_cmk\_key\_vault\_key\_id is set. | `bool` | `false` | no |
| <a name="input_managed_resource_group_name"></a> [managed\_resource\_group\_name](#input\_managed\_resource\_group\_name) | Optional name for the managed resource group that Azure Databricks creates for control-plane resources. If null, Azure generates a name automatically. | `string` | `null` | no |
| <a name="input_managed_services_cmk_key_vault_key_id"></a> [managed\_services\_cmk\_key\_vault\_key\_id](#input\_managed\_services\_cmk\_key\_vault\_key\_id) | Key Vault key ID for managed services (notebooks, artifacts) encryption. Requires customer\_managed\_key\_enabled = true and premium SKU. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Azure Databricks workspace resource. Must be unique within the resource group. | `string` | n/a | yes |
| <a name="input_network_security_group_rules_required"></a> [network\_security\_group\_rules\_required](#input\_network\_security\_group\_rules\_required) | Determines NSG rule enforcement. Valid values: "AllRules", "NoAzureDatabricksRules", "NoAzureServiceRules". Typically "AllRules" for VNet injection; null defers to Azure default. | `string` | `null` | no |
| <a name="input_no_public_ip"></a> [no\_public\_ip](#input\_no\_public\_ip) | Enable Secure Cluster Connectivity (SCC / No Public IP). When true, cluster nodes have no public IPs. Recommended for production. Requires VNet injection. | `bool` | `false` | no |
| <a name="input_private_subnet_network_security_group_association_id"></a> [private\_subnet\_network\_security\_group\_association\_id](#input\_private\_subnet\_network\_security\_group\_association\_id) | Resource ID of the NSG association for the private (container) subnet. Required when virtual\_network\_id is set. | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Allow public network access to the workspace front-end. Set to false to require private connectivity only. | `bool` | `true` | no |
| <a name="input_public_subnet_network_security_group_association_id"></a> [public\_subnet\_network\_security\_group\_association\_id](#input\_public\_subnet\_network\_security\_group\_association\_id) | Resource ID of the NSG association for the public (host) subnet. Required when virtual\_network\_id is set. | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the Azure resource group in which to create the Databricks workspace. | `string` | n/a | yes |
| <a name="input_root_dbfs_cmk_key_vault_id"></a> [root\_dbfs\_cmk\_key\_vault\_id](#input\_root\_dbfs\_cmk\_key\_vault\_id) | Resource ID of the Key Vault containing root\_dbfs\_cmk\_key\_vault\_key\_id. Required only when the Key Vault is in a different subscription than the workspace. | `string` | `null` | no |
| <a name="input_root_dbfs_cmk_key_vault_key_id"></a> [root\_dbfs\_cmk\_key\_vault\_key\_id](#input\_root\_dbfs\_cmk\_key\_vault\_key\_id) | Key Vault key ID for root DBFS encryption via azurerm\_databricks\_workspace\_root\_dbfs\_customer\_managed\_key. When set, root DBFS CMK is configured as a post-creation step. | `string` | `null` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | Databricks workspace SKU. Use "premium" for Unity Catalog, IP access lists, cluster policies with ACLs, and all Premium features. Use "standard" for basic workspaces only. | `string` | `"premium"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the Azure Databricks workspace resource. | `map(string)` | `{}` | no |
| <a name="input_virtual_network_id"></a> [virtual\_network\_id](#input\_virtual\_network\_id) | Resource ID of the Azure VNet for VNet injection. When set, host\_subnet\_name and container\_subnet\_name must also be set. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_disk_encryption_set_id"></a> [disk\_encryption\_set\_id](#output\_disk\_encryption\_set\_id) | Resource ID of the Managed Disk Encryption Set. Populated only when managed\_disk\_cmk\_key\_vault\_key\_id is set. |
| <a name="output_managed_disk_identity"></a> [managed\_disk\_identity](#output\_managed\_disk\_identity) | Managed identity of the managed disk encryption set (principal\_id, tenant\_id, type). Used for Key Vault access policies when disk CMK is enabled. |
| <a name="output_managed_resource_group_id"></a> [managed\_resource\_group\_id](#output\_managed\_resource\_group\_id) | Azure Resource Manager resource ID of the managed resource group created by Databricks for control-plane resources. |
| <a name="output_storage_account_identity"></a> [storage\_account\_identity](#output\_storage\_account\_identity) | Managed identity of the default storage account (principal\_id, tenant\_id, type). Used for Key Vault access policies when CMK is enabled. |
| <a name="output_workspace_id"></a> [workspace\_id](#output\_workspace\_id) | Databricks workspace ID (numeric). Used as the identifier within the Databricks control plane. |
| <a name="output_workspace_resource_id"></a> [workspace\_resource\_id](#output\_workspace\_resource\_id) | Azure Resource Manager resource ID of the Databricks workspace. Used for RBAC assignments, policy, and diagnostic settings. |
| <a name="output_workspace_url"></a> [workspace\_url](#output\_workspace\_url) | Workspace URL in the format adb-{id}.{n}.azuredatabricks.net. Use as the host for the workspace-scoped Databricks provider. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- VNet injection local is true/false based on `virtual_network_id` presence.
- Extended compliance standards trigger `azapi_update_resource`.
- All variable validations (SKU, NSG rules, compliance standards).
- Workspace resource is planned with expected name.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Azure + Databricks account) verifies actual workspace creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
