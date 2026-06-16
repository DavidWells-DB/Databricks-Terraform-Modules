# azure-account-workspace-storage

Creates an Azure Data Lake Storage Gen2 (ADLS Gen2) account and container for use as Databricks Unity Catalog metastore storage or workspace root storage on Azure.

## What this module abstracts

"The ADLS Gen2 storage that Databricks uses for this workspace or metastore" — a single cohesive function. The storage account and its container are always created together and are meaningless without each other in a Databricks context. This module produces the `storage_account_name`, `storage_account_id`, `container_name`, and `dfs_endpoint` outputs that downstream modules (UC metastore, workspace access connector role assignment) consume.

## When to use

- You are provisioning ADLS Gen2 storage for a Databricks Unity Catalog metastore on Azure.
- You are provisioning ADLS Gen2 storage for a Databricks workspace root on Azure.
- You want a single module that creates both the storage account and the container with secure defaults (HTTPS-only, TLS 1.2, HNS enabled, public access blocked).

## When NOT to use

- You already have an ADLS Gen2 storage account — reference it with `data "azurerm_storage_account"` in the root composition and pass the outputs to downstream modules directly.
- You need a standard Blob Storage account (non-HNS) — this module always enables the hierarchical namespace required for ADLS Gen2.
- You are on AWS or GCP — those clouds use S3 and GCS respectively; see `aws-account-workspace-storage`.

## Minimum platform tier

**Premium.** Unity Catalog (the primary consumer of this storage) requires a Premium-tier Databricks account. Workspace root storage created by this module is compatible with Standard tier, but the UC use case requires Premium. See DATABRICKS_RULES.md Rule 2.3.

## Azure Government notes

Azure Government (IL5) deployments require CMK encryption. Set `kms_key_id` to the resource ID of a Key Vault key in the same region. The storage account will use a system-assigned managed identity to access the key — grant it the Key Vault Crypto Service Encryption User role at the root composition. The `azurerm` provider `environment = "usgovernment"` setting is a provider-level concern handled at the root composition; this module is environment-agnostic.

## Provider configuration

This module uses only the `azurerm` provider. No Databricks provider is required; the module produces storage-side outputs that a separate module (e.g., an access connector or UC metastore module) wires into Databricks. The `azurerm` provider must be configured with appropriate credentials (service principal or managed identity) at the root composition.

## Storage account naming

The storage account name is constructed as `${resource_prefix}stor`. Azure storage account names must be globally unique, 3-24 characters, lowercase alphanumeric. The `resource_prefix` is validated to 1-16 lowercase alphanumeric characters; choose a prefix that includes a workspace name or a random suffix to ensure global uniqueness (e.g., `"myorg42"`).

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.50 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.50 |

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
| <a name="input_account_replication_type"></a> [account\_replication\_type](#input\_account\_replication\_type) | Replication type for the storage account (LRS, GRS, ZRS, GZRS, RA-GRS, RA-GZRS). LRS is the minimum required for Databricks; choose based on your DR requirements. | `string` | `"LRS"` | no |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | Azure storage account tier. Use "Standard" for most workloads; "Premium" for latency-sensitive scenarios. | `string` | `"Standard"` | no |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Name of the ADLS Gen2 container (filesystem) to create inside the storage account. Defaults to "databricks" when null. | `string` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Resource ID of an Azure Key Vault key to use for customer-managed encryption (CMK). When null, Microsoft-managed keys are used. Required for Azure Government IL5 deployments. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region (e.g. "eastus", "westeurope") for all resources. | `string` | n/a | yes |
| <a name="input_min_tls_version"></a> [min\_tls\_version](#input\_min\_tls\_version) | Minimum TLS version enforced on the storage account. Databricks recommends TLS 1.2 or higher. | `string` | `"TLS1_2"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the Azure resource group in which to create storage resources. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix applied to all resource names. Must be 1-16 characters, lowercase alphanumeric only. Combined with fixed suffixes to form the storage account name (max 24 chars total). | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all Azure resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_container_name"></a> [container\_name](#output\_container\_name) | Name of the ADLS Gen2 container (filesystem) created inside the storage account. |
| <a name="output_dfs_endpoint"></a> [dfs\_endpoint](#output\_dfs\_endpoint) | Primary DFS (Data Lake Storage Gen2) endpoint URL for the storage account. Used as the external location path in Unity Catalog. |
| <a name="output_primary_blob_endpoint"></a> [primary\_blob\_endpoint](#output\_primary\_blob\_endpoint) | Primary blob endpoint URL for the storage account. Useful for constructing abfss:// paths. |
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | Azure resource ID of the storage account. Used for RBAC role assignments (e.g. granting the Access Connector Storage Blob Data Contributor). |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Name of the ADLS Gen2 storage account. Pass to a Unity Catalog metastore or workspace module as the storage account identifier. |
| <a name="output_storage_account_principal_id"></a> [storage\_account\_principal\_id](#output\_storage\_account\_principal\_id) | Object ID of the storage account's system-assigned managed identity. Populated only when kms\_key\_id is set (CMK mode). Null otherwise. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Default container name (`"databricks"`) when `container_name` is null
- Custom container name is passed through
- Storage account name is constructed from `resource_prefix` + `"stor"`
- Invalid `resource_prefix` values rejected by variable validation
- Invalid `container_name` values rejected by variable validation
- Invalid `account_tier`, `account_replication_type`, and `min_tls_version` rejected

Run with `terraform test` from the module root.

An apply-command integration test (against a real Azure subscription) verifies actual storage account and container creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
