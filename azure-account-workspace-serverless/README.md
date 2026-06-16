# azure-account-workspace-serverless

Creates an Azure Databricks workspace without VNet injection, configured for serverless compute only. This is the minimal workspace footprint for teams that rely exclusively on serverless SQL warehouses and serverless jobs, with no classic cluster compute.

## What this module abstracts

"A serverless-only Azure Databricks workspace" — the `azurerm_databricks_workspace` resource configured without `custom_parameters` (no VNet injection). Omitting VNet injection is the Azure-native serverless pattern: the workspace delegates all compute networking to the Databricks serverless infrastructure rather than managing VNet/subnet wiring in the customer subscription.

## When to use

- You are provisioning a new Azure Databricks workspace and all compute will run on serverless (serverless SQL warehouses, serverless jobs, serverless DLT pipelines).
- You want the smallest possible Azure footprint — no VNet, no subnets, no NSGs managed in your subscription.
- You are adopting the Azure Databricks serverless-first architecture recommended by Databricks for new accounts.

## When NOT to use

- You need classic cluster compute (interactive clusters, classic jobs clusters) — use `azure-account-workspace` with VNet injection instead.
- You need Secure Cluster Connectivity (no-public-IP) for classic clusters — requires VNet injection; use `azure-account-workspace`.
- You need private endpoints for workspace front-end connectivity — private endpoint wiring is a root-composition concern; this module exposes `workspace_resource_id` for that purpose.

## Minimum platform tier

**Premium.** Serverless compute on Azure Databricks requires a Premium-tier workspace (SKU `premium`). The default `sku = "premium"`. Deploying with `sku = "standard"` will create the workspace but serverless compute features will be unavailable. See DATABRICKS_RULES.md Rule 2.3.

## Azure Government notes

Azure Government deployments are parameterized at the provider level via `environment = "usgovernment"` in the `azurerm` provider block — this is a root-composition concern, not a module input. This module is environment-agnostic. For Azure Government IL5 deployments, enable CMK via `managed_services_cmk_key_vault_key_id` and `infrastructure_encryption_enabled = true`.

## Provider configuration

This module uses only the `azurerm` provider (no Databricks provider required at the account layer for Azure — workspace creation is entirely via the Azure ARM API). Configure the `azurerm` provider with a service principal or managed identity that has `Contributor` on the target resource group and `Owner` or `User Access Administrator` if RBAC assignments are needed. The `features {}` block is required by the provider at the root composition.

## Customer-managed keys

Optional CMK support is provided for three encryption surfaces:

| Surface | Variable |
|---|---|
| Managed services (notebooks, artifacts) | `managed_services_cmk_key_vault_key_id` + `customer_managed_key_enabled = true` |
| Managed disks | `managed_disk_cmk_key_vault_key_id` |
| Root DBFS | `root_dbfs_cmk_key_vault_key_id` (post-creation via `azurerm_databricks_workspace_root_dbfs_customer_managed_key`) |

All CMK features require `sku = "premium"`.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.76 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.76 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_databricks_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace) | resource |
| [azurerm_databricks_workspace_root_dbfs_customer_managed_key.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace_root_dbfs_customer_managed_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_connector_id"></a> [access\_connector\_id](#input\_access\_connector\_id) | Resource ID of the Azure Databricks Access Connector. Required when default\_storage\_firewall\_enabled = true. | `string` | `null` | no |
| <a name="input_customer_managed_key_enabled"></a> [customer\_managed\_key\_enabled](#input\_customer\_managed\_key\_enabled) | Enable customer-managed key for managed services encryption. Requires premium SKU and managed\_services\_cmk\_key\_vault\_key\_id. | `bool` | `false` | no |
| <a name="input_default_storage_firewall_enabled"></a> [default\_storage\_firewall\_enabled](#input\_default\_storage\_firewall\_enabled) | Disallow public access to the default storage account. When true, access\_connector\_id must also be set. | `bool` | `false` | no |
| <a name="input_infrastructure_encryption_enabled"></a> [infrastructure\_encryption\_enabled](#input\_infrastructure\_encryption\_enabled) | Enable a secondary layer of encryption for workspace data at rest. Requires premium SKU. Immutable after workspace creation. | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the workspace (e.g., "eastus", "westeurope"). Must match the resource group region. | `string` | n/a | yes |
| <a name="input_managed_disk_cmk_key_vault_key_id"></a> [managed\_disk\_cmk\_key\_vault\_key\_id](#input\_managed\_disk\_cmk\_key\_vault\_key\_id) | Key Vault key ID for managed disk encryption. Requires premium SKU. | `string` | `null` | no |
| <a name="input_managed_disk_cmk_rotation_to_latest_version_enabled"></a> [managed\_disk\_cmk\_rotation\_to\_latest\_version\_enabled](#input\_managed\_disk\_cmk\_rotation\_to\_latest\_version\_enabled) | Automatically rotate managed disk CMK to the latest key version. Only relevant when managed\_disk\_cmk\_key\_vault\_key\_id is set. | `bool` | `false` | no |
| <a name="input_managed_resource_group_name"></a> [managed\_resource\_group\_name](#input\_managed\_resource\_group\_name) | Optional name for the managed resource group that Azure Databricks creates for control-plane resources. If null, Azure generates a name automatically. | `string` | `null` | no |
| <a name="input_managed_services_cmk_key_vault_key_id"></a> [managed\_services\_cmk\_key\_vault\_key\_id](#input\_managed\_services\_cmk\_key\_vault\_key\_id) | Key Vault key ID for managed services (notebooks, artifacts) encryption. Requires customer\_managed\_key\_enabled = true and premium SKU. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Azure Databricks workspace resource. Must be unique within the resource group. | `string` | n/a | yes |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Allow public network access to the workspace front-end. Set to false to require private connectivity only (requires private endpoints wired by the root composition). | `bool` | `true` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the Azure resource group in which to create the Databricks workspace. | `string` | n/a | yes |
| <a name="input_root_dbfs_cmk_key_vault_id"></a> [root\_dbfs\_cmk\_key\_vault\_id](#input\_root\_dbfs\_cmk\_key\_vault\_id) | Resource ID of the Key Vault containing root\_dbfs\_cmk\_key\_vault\_key\_id. Required only when the Key Vault is in a different subscription than the workspace. | `string` | `null` | no |
| <a name="input_root_dbfs_cmk_key_vault_key_id"></a> [root\_dbfs\_cmk\_key\_vault\_key\_id](#input\_root\_dbfs\_cmk\_key\_vault\_key\_id) | Key Vault key ID for root DBFS encryption via azurerm\_databricks\_workspace\_root\_dbfs\_customer\_managed\_key. When set, root DBFS CMK is configured as a post-creation step. | `string` | `null` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | Databricks workspace SKU. Use "premium" for serverless compute, Unity Catalog, and all Premium features. "standard" does not support serverless compute. | `string` | `"premium"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the Azure Databricks workspace resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_disk_encryption_set_id"></a> [disk\_encryption\_set\_id](#output\_disk\_encryption\_set\_id) | Resource ID of the Managed Disk Encryption Set. Populated only when managed\_disk\_cmk\_key\_vault\_key\_id is set. |
| <a name="output_managed_disk_identity"></a> [managed\_disk\_identity](#output\_managed\_disk\_identity) | Managed identity of the managed disk encryption set (principal\_id, tenant\_id, type). Used for Key Vault access policies when disk CMK is enabled. |
| <a name="output_managed_resource_group_id"></a> [managed\_resource\_group\_id](#output\_managed\_resource\_group\_id) | Azure Resource Manager resource ID of the managed resource group created by Databricks for control-plane resources. |
| <a name="output_storage_account_identity"></a> [storage\_account\_identity](#output\_storage\_account\_identity) | Managed identity of the default storage account (principal\_id, tenant\_id, type). Used for Key Vault access policies when CMK is enabled. |
| <a name="output_workspace_id"></a> [workspace\_id](#output\_workspace\_id) | Databricks workspace ID (numeric). Used as the identifier within the Databricks control plane. |
| <a name="output_workspace_resource_id"></a> [workspace\_resource\_id](#output\_workspace\_resource\_id) | Azure Resource Manager resource ID of the Databricks workspace. Used for RBAC assignments, policy, and diagnostic settings. |
| <a name="output_workspace_url"></a> [workspace\_url](#output\_workspace\_url) | Workspace URL in the format https://adb-{id}.{n}.azuredatabricks.net. Use as the host for the workspace-scoped Databricks provider. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Workspace resource is planned with expected `name`, `location`, `resource_group_name`, and `sku`.
- No `custom_parameters` block — serverless workspaces omit VNet injection.
- Invalid `name` values rejected by variable validation (too short, too long, invalid chars).
- Invalid `sku` value rejected by variable validation.
- Root DBFS CMK resource created only when `root_dbfs_cmk_key_vault_key_id` is set.
- Root DBFS CMK resource absent when key is not set.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Azure subscription) verifies actual workspace creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
