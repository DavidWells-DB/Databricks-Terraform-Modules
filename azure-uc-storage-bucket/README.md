# azure-uc-storage-bucket

Creates the dedicated ADLS Gen2 storage account + container for a Unity Catalog catalog's managed storage. Best practice (OKF unity-catalog): catalog data on its own bucket/container — never the workspace root the platform's workspace catalog shares. CREATE side of create-vs-adopt (Rule 8.4); the adopt side passes an existing bucket + path to the composition.

## When to use

- Composing a catalog with dedicated managed storage (the domain-catalog components' default mode).
- You need a UC-ready bucket/container with sane security defaults as a standalone primitive.

## When NOT to use

- The catalog should live on the metastore's default managed storage (no dedicated bucket) — omit the storage wiring instead.
- You already have the bucket — pass it directly to the composition (adopt), don't recreate it.


## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.70 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 5.11.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the storage account (e.g. "eastus"). | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the Azure resource group for the storage account. | `string` | n/a | yes |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Name of the dedicated ADLS Gen2 storage account. Globally unique across Azure, lowercase alphanumeric, 3-24 chars. A common convention is "<catalog-name-without-underscores>ucst". | `string` | n/a | yes |
| <a name="input_account_replication_type"></a> [account\_replication\_type](#input\_account\_replication\_type) | Replication type for the storage account (LRS / ZRS / GRS / GZRS). | `string` | `"LRS"` | no |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | Storage account tier. "Standard" for catalog managed storage. | `string` | `"Standard"` | no |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Name of the dedicated container for the catalog's managed data. | `string` | `"catalog"` | no |
| <a name="input_min_tls_version"></a> [min\_tls\_version](#input\_min\_tls\_version) | Minimum TLS version for the storage account. | `string` | `"TLS1_2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the storage account. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_container_name"></a> [container\_name](#output\_container\_name) | Name of the dedicated container for the catalog's managed data. |
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | ARM resource ID of the dedicated ADLS Gen2 storage account. Feed to azure-uc-storage-credential's storage\_account\_id. |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Name of the dedicated ADLS Gen2 storage account. |
| <a name="output_storage_root"></a> [storage\_root](#output\_storage\_root) | The Unity Catalog storage-root URL (abfss://<container>@<account>.dfs.core.windows.net). Append the catalog's path suffix at the composition. |
<!-- END_TF_DOCS -->
