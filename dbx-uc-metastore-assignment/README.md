# dbx-uc-metastore-assignment

Assigns a Unity Catalog metastore to one or more Databricks workspaces and optionally sets a default catalog for a specific workspace.

## What this module abstracts

"The workspace-to-metastore binding" — attaching a UC metastore to workspaces is the bootstrapping step that unlocks Unity Catalog for those workspaces. The module iterates over a map of workspace IDs and creates a `databricks_metastore_assignment` for each, using the account-level provider. An optional `databricks_default_namespace_setting` sets the default catalog for the single workspace targeted by the `databricks.workspace` provider alias.

## When to use

- You have a metastore (created by `dbx-uc-metastore` or looked up via data source) and need to assign it to one or more workspaces.
- You want a single module call to cover all assignments in a region.
- You optionally want to configure a default catalog for a specific workspace.

## When NOT to use

- You need to set a default catalog on more than one workspace — call this module once per workspace, each with a distinct `databricks.workspace` provider alias, or manage the per-workspace setting with separate `databricks_default_namespace_setting` resources in your root composition.
- The metastore doesn't exist yet — create it first with `dbx-uc-metastore` and pass its ID here.

## Minimum platform tier

**Premium.** Unity Catalog is a Premium-tier feature. Applying this module against a Standard-tier workspace will fail at the API layer. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

This module is a Unity Catalog bridging module per DATABRICKS_RULES.md Rule 1.1 and declares two provider aliases via `configuration_aliases`:

| Alias | Required? | Purpose |
|---|---|---|
| `databricks.account` | Always | Creates `databricks_metastore_assignment` for each workspace |
| `databricks.workspace` | Required when `default_catalog_name` is set | Creates `databricks_default_namespace_setting` on the target workspace |

Configure `databricks.account` against the Databricks account host:
- Commercial: `https://accounts.cloud.databricks.com`
- GovCloud (civilian): `https://accounts.cloud.databricks.us`
- GovCloud (DoD): `https://accounts-dod.cloud.databricks.mil`

Configure `databricks.workspace` against the workspace URL of the workspace for which you want to set a default catalog.

Even when `default_catalog_name = null`, the caller must still pass both provider aliases at the call site because Terraform requires all `configuration_aliases` to be satisfied. Configure the workspace provider with any valid workspace URL; it will not be used.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.50 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | >= 1.50 |
| <a name="provider_databricks.workspace"></a> [databricks.workspace](#provider\_databricks.workspace) | >= 1.50 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_default_namespace_setting.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/default_namespace_setting) | resource |
| [databricks_metastore_assignment.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/metastore_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_default_catalog_name"></a> [default\_catalog\_name](#input\_default\_catalog\_name) | Catalog to set as the default namespace for the workspace configured in the<br/>databricks.workspace provider alias. When set, a databricks\_default\_namespace\_setting<br/>resource is created for that workspace. When null, no default catalog is configured.<br/>Requires the databricks.workspace provider alias to be configured against the target<br/>workspace URL. | `string` | `null` | no |
| <a name="input_metastore_id"></a> [metastore\_id](#input\_metastore\_id) | ID of the Unity Catalog metastore to assign. Obtain from the databricks\_metastore resource or a data source. | `string` | n/a | yes |
| <a name="input_workspace_ids"></a> [workspace\_ids](#input\_workspace\_ids) | Map of workspace assignments. Keys are human-readable labels; values are numeric Databricks<br/>workspace IDs. The metastore will be assigned to every workspace in this map.<br/><br/>Example:<br/>  workspace\_ids = {<br/>    prod = "123456789012345"<br/>    dev  = "234567890123456"<br/>  } | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_assigned_workspace_ids"></a> [assigned\_workspace\_ids](#output\_assigned\_workspace\_ids) | Map of assignment labels to the numeric workspace IDs that were assigned the metastore. Mirrors var.workspace\_ids; useful for downstream references. |
| <a name="output_assignment_ids"></a> [assignment\_ids](#output\_assignment\_ids) | Map of assignment labels to metastore assignment IDs (format: <workspace\_id>\|<metastore\_id>). Keys match the keys of var.workspace\_ids. |
| <a name="output_default_catalog_name"></a> [default\_catalog\_name](#output\_default\_catalog\_name) | Default catalog name configured via databricks\_default\_namespace\_setting, or null if not set. |
| <a name="output_metastore_id"></a> [metastore\_id](#output\_metastore\_id) | ID of the metastore that was assigned. Echoed from input for use in downstream module compositions. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Metastore assignment resources are planned with expected attributes for each workspace
- Invalid `metastore_id` (not a UUID) is rejected by variable validation
- Empty `workspace_ids` map is rejected by variable validation
- Non-numeric workspace ID values are rejected by variable validation
- Invalid `default_catalog_name` (leading whitespace) is rejected by variable validation
- `databricks_default_namespace_setting` is created when `default_catalog_name` is set, skipped when null

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks account + workspace) verifies actual metastore assignment. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
