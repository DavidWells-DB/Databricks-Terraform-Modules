# azure-account-encryption-keys

Creates an Azure Key Vault with three CMK (customer-managed key) RSA-2048 keys for Databricks workspace encryption — managed services, workspace storage (DBFS root), and managed disk — plus the access policies that allow the Databricks service principal to wrap and unwrap keys.

## What this module abstracts

"The encryption keys Databricks uses for this workspace" — one indivisible function. The Key Vault, its three keys, and the Databricks access policy are always created together; splitting them produces thin wrappers with no independent reuse.

Unlike the AWS equivalent, there is no Databricks-side registration step: the key IDs flow directly into `azurerm_databricks_workspace` arguments (`managed_services_cmk_key_vault_key_id`, `managed_disk_cmk_key_vault_key_id`) and into the post-creation `azurerm_databricks_workspace_root_dbfs_customer_managed_key` resource, both of which are handled in the `azure-account-workspace` module.

## When to use

- You are provisioning a new Azure-hosted Databricks workspace and need CMK encryption for one or more of: managed services, DBFS root storage, and managed disks.
- You want a single module that creates the Key Vault, all three keys, and the correct access policies in one operation.

## When NOT to use

- You already have an Azure Key Vault you want to reuse — add keys and access policies directly to it at the root composition instead.
- You need only one or two of the three CMK types — this module always creates all three. If that wastes keys, create them individually at root.
- You are on AWS or GCP — those clouds use different CMK mechanisms (`aws-account-encryption-keys`).

## Minimum platform tier

**Premium.** CMK for managed services and DBFS root requires the Databricks Premium plan. The Databricks Terraform provider does not check tier at plan time; applying against a Standard-tier workspace will fail at the workspace creation step (not at key creation). See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Azure Government notes

Azure Government (USGov) parameterization is a provider-level concern handled in root compositions via `azurerm` provider `environment = "usgovernment"`. The Key Vault private DNS zone suffix changes from `privatelink.vaultcore.azure.net` (commercial) to `privatelink.vaultcore.usgovcloudapi.net` for Azure Government. When deploying to Azure Government, set the `private_endpoint` input's DNS zone to the appropriate suffix by using a separate root composition rather than this module's default.

## Provider configuration

This module requires only the `azurerm` provider — no Databricks provider is needed, because no Databricks-side resource registration occurs here. Configure the `azurerm` provider at the root composition with the appropriate `tenant_id`, `subscription_id`, and authentication method.

## Key access policies

Two access policies are created:

| Policy | Object | Permissions |
|---|---|---|
| `terraform` | `azure_client_object_id` (Terraform runner) | Create, Delete, Get, GetRotationPolicy, List, Purge, Recover, Update, WrapKey, UnwrapKey |
| `databricks` | `databricks_service_principal_object_id` | Get, WrapKey, UnwrapKey |

The `databricks_service_principal_object_id` is the object ID of the `AzureDatabricks` first-party enterprise application in your Azure AD tenant. It can be found via: `az ad sp show --id "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d" --query id -o tsv`.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.75 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.75 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_access_policy.databricks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_key.managed_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key) | resource |
| [azurerm_key_vault_key.managed_services](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key) | resource |
| [azurerm_key_vault_key.workspace_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key) | resource |
| [azurerm_private_dns_zone.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_azure_client_object_id"></a> [azure\_client\_object\_id](#input\_azure\_client\_object\_id) | Object ID of the Azure service principal or user running Terraform. Granted full key management permissions so that Terraform can create and manage keys. | `string` | n/a | yes |
| <a name="input_databricks_service_principal_object_id"></a> [databricks\_service\_principal\_object\_id](#input\_databricks\_service\_principal\_object\_id) | Object ID of the AzureDatabricks enterprise application in your Azure AD tenant. Used in the Key Vault access policy granting Databricks permission to wrap/unwrap keys. | `string` | n/a | yes |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Name of the Azure Key Vault. Must be globally unique, 3-24 characters, alphanumeric and hyphens only, start with a letter. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the Key Vault (e.g. "eastus", "westeurope"). | `string` | n/a | yes |
| <a name="input_network_acls"></a> [network\_acls](#input\_network\_acls) | Network ACL configuration for the Key Vault. default\_action must be "Allow" or "Deny"; bypass must be "AzureServices" or "None" (use "AzureServices" for Databricks control-plane access). The default restricts public access; supply ip\_rules or virtual\_network\_subnet\_ids to allow specific sources. | <pre>object({<br/>    default_action             = string<br/>    bypass                     = string<br/>    ip_rules                   = optional(set(string), [])<br/>    virtual_network_subnet_ids = optional(set(string), [])<br/>  })</pre> | <pre>{<br/>  "bypass": "AzureServices",<br/>  "default_action": "Deny",<br/>  "ip_rules": []<br/>}</pre> | no |
| <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint) | Optional private endpoint configuration for the Key Vault. When set, creates an azurerm\_private\_endpoint in the given subnet and a private DNS zone linked to the given VNet. Set to null to skip private endpoint creation. | <pre>object({<br/>    subnet_id           = string<br/>    vnet_id             = string<br/>    resource_group_name = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the Azure resource group where the Key Vault will be created. | `string` | n/a | yes |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | Number of days to retain soft-deleted Key Vault objects. Must be between 7 and 90. Required for Premium SKU. | `number` | `7` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources created by this module (Key Vault, keys, private endpoint). | `map(string)` | `{}` | no |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | Azure Active Directory tenant ID. Must be a valid UUID. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_key_vault_id"></a> [key\_vault\_id](#output\_key\_vault\_id) | Resource ID of the Azure Key Vault. Pass to azurerm\_databricks\_workspace as managed\_services\_cmk\_key\_vault\_id and managed\_disk\_cmk\_key\_vault\_id. |
| <a name="output_key_vault_name"></a> [key\_vault\_name](#output\_key\_vault\_name) | Name of the Azure Key Vault. |
| <a name="output_key_vault_uri"></a> [key\_vault\_uri](#output\_key\_vault\_uri) | URI of the Azure Key Vault (e.g. https://<name>.vault.azure.net/). Used to construct key version URLs. |
| <a name="output_managed_disk_key_id"></a> [managed\_disk\_key\_id](#output\_managed\_disk\_key\_id) | Versioned resource ID of the managed-disk CMK. Pass to azurerm\_databricks\_workspace as managed\_disk\_cmk\_key\_vault\_key\_id. |
| <a name="output_managed_disk_key_versionless_id"></a> [managed\_disk\_key\_versionless\_id](#output\_managed\_disk\_key\_versionless\_id) | Versionless resource ID of the managed-disk CMK. Useful for callers that need to reference the key without pinning to a specific version. |
| <a name="output_managed_services_key_id"></a> [managed\_services\_key\_id](#output\_managed\_services\_key\_id) | Versioned resource ID of the managed-services CMK. Pass to azurerm\_databricks\_workspace as managed\_services\_cmk\_key\_vault\_key\_id. |
| <a name="output_managed_services_key_versionless_id"></a> [managed\_services\_key\_versionless\_id](#output\_managed\_services\_key\_versionless\_id) | Versionless resource ID of the managed-services CMK. Useful for callers that need to reference the key without pinning to a specific version. |
| <a name="output_private_endpoint_id"></a> [private\_endpoint\_id](#output\_private\_endpoint\_id) | Resource ID of the Key Vault private endpoint. Null when private\_endpoint input is not set. |
| <a name="output_workspace_storage_key_id"></a> [workspace\_storage\_key\_id](#output\_workspace\_storage\_key\_id) | Versioned resource ID of the workspace-storage CMK (DBFS root). Pass to azurerm\_databricks\_workspace\_root\_dbfs\_customer\_managed\_key. |
| <a name="output_workspace_storage_key_versionless_id"></a> [workspace\_storage\_key\_versionless\_id](#output\_workspace\_storage\_key\_versionless\_id) | Versionless resource ID of the workspace-storage CMK. Useful for callers that need to reference the key without pinning to a specific version. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid inputs produce the expected Key Vault and key resource attributes.
- Variable validation rejects: invalid key_vault_name (too short, too long, invalid chars, trailing hyphen), invalid UUID format for tenant_id, databricks_service_principal_object_id, azure_client_object_id, and out-of-range soft_delete_retention_days.
- Private endpoint conditional: resources are planned when private_endpoint is set, skipped when null.
- Locals: pe_resource_group_name falls back to resource_group_name when not overridden.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Azure subscription) verifies actual Key Vault and key creation. It is credential-gated and added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
