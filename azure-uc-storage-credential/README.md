# azure-uc-storage-credential

Creates an Azure Databricks Access Connector with a SystemAssigned managed identity, assigns it the **Storage Blob Data Contributor** role on a target ADLS Gen2 storage account, and registers the identity as a `databricks_storage_credential` for Unity Catalog.

## What this module abstracts

"The storage credential Databricks UC uses to read/write this Azure storage account" — one indivisible function. The Azure Access Connector and its Databricks-side registration are paired per DATABRICKS_RULES.md Rule 1.4: splitting them produces thin wrappers; pairing them produces a real abstraction.

## When to use

- You're setting up Azure Unity Catalog and need to grant Databricks UC access to an ADLS Gen2 storage account.
- You want a single module that creates the Access Connector, assigns the Azure RBAC role, AND registers the credential with Databricks.
- You're configuring the default data access credential for a metastore, or creating additional storage credentials for external locations.

## When NOT to use

- You already have an `azurerm_databricks_access_connector` managed elsewhere — reference it with a `data` source at the root composition and pass its ID directly to `databricks_storage_credential`.
- You're on AWS or GCP — they use different credential mechanisms (`aws-account-workspace-credentials` or `gcp-uc-storage-credential`).
- Your Access Connector is shared across multiple storage credentials — use a `data` source for the connector and call `databricks_storage_credential` directly.

## Minimum platform tier

**Premium.** Unity Catalog requires a Premium-tier (or higher) Databricks workspace. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier workspace, the API will reject and apply will fail. See DATABRICKS_RULES.md Rules 2.3 and 4.1.

## Azure Government

Azure Government is parameterized via the `azurerm` provider `environment = "usgovernment"` setting, which is a provider-level concern handled at the root composition. No module input is required. The `location` variable accepts Azure Government region names (e.g., `"usgovvirginia"`, `"usgovarizona"`).

## Provider configuration

The module declares `configuration_aliases = [databricks.workspace]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.workspace` provider configured against the target workspace URL. The `azurerm` provider must be configured for the subscription containing the target resource group and storage account.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.75 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.49 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.75 |
| <a name="provider_databricks.workspace"></a> [databricks.workspace](#provider\_databricks.workspace) | >= 1.49 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_databricks_access_connector.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_access_connector) | resource |
| [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [databricks_storage_credential.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/storage_credential) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_connector_name"></a> [access\_connector\_name](#input\_access\_connector\_name) | Name of the Azure Databricks Access Connector resource. Defaults to "dbx-access-connector-<credential\_name>" when null. | `string` | `null` | no |
| <a name="input_comment"></a> [comment](#input\_comment) | Human-readable comment attached to the databricks\_storage\_credential. Optional. | `string` | `null` | no |
| <a name="input_credential_name"></a> [credential\_name](#input\_credential\_name) | Name for the databricks\_storage\_credential registration. Must be unique within the Databricks workspace. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the Access Connector (e.g. "eastus", "westeurope"). Must match the region of the storage account. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the Azure resource group in which to create the Access Connector. | `string` | n/a | yes |
| <a name="input_skip_validation"></a> [skip\_validation](#input\_skip\_validation) | When true, Databricks skips the automatic credential validation step during storage credential creation. Set to true in environments where validation cannot complete (e.g., locked-down VNets). | `bool` | `false` | no |
| <a name="input_storage_account_id"></a> [storage\_account\_id](#input\_storage\_account\_id) | Full Azure resource ID of the ADLS Gen2 storage account to which Storage Blob Data Contributor will be assigned. Format: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{name}. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the Azure Databricks Access Connector resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_connector_id"></a> [access\_connector\_id](#output\_access\_connector\_id) | Full Azure resource ID of the Databricks Access Connector. Pass to other modules or external locations that reference this credential. |
| <a name="output_access_connector_principal_id"></a> [access\_connector\_principal\_id](#output\_access\_connector\_principal\_id) | Object ID of the Access Connector's SystemAssigned managed identity. Useful for constructing additional Azure role assignments. |
| <a name="output_storage_credential_id"></a> [storage\_credential\_id](#output\_storage\_credential\_id) | Databricks Unity Catalog storage credential ID. Pass to databricks\_external\_location or other UC resources that require a storage credential. |
| <a name="output_storage_credential_name"></a> [storage\_credential\_name](#output\_storage\_credential\_name) | Name of the Databricks Unity Catalog storage credential, as registered. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Default `access_connector_name` is derived from `credential_name`
- Explicit `access_connector_name` overrides the default
- Invalid `resource_group_name` is rejected by variable validation
- Invalid `location` is rejected by variable validation
- Invalid `storage_account_id` is rejected by variable validation
- Invalid `credential_name` is rejected by variable validation
- Storage credential resource is planned with expected name and `skip_validation = false`

Run with `terraform test` from the module root.

An apply-command integration test (against a real Azure subscription + Databricks workspace) verifies actual Access Connector creation, role assignment, and storage credential registration. It is credential-gated (per DATABRICKS_RULES.md Rule 4.1).
