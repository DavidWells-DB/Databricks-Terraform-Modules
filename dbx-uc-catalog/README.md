# dbx-uc-catalog

Creates Unity Catalog catalogs in a Databricks workspace, with optional managed storage root, isolation mode, and privilege grants per catalog.

## What this module abstracts

"The catalog layer of a Unity Catalog hierarchy" — a cohesive operational unit. The module creates one or more `databricks_catalog` resources via `for_each` and, for each catalog that declares grants, one authoritative `databricks_grants` resource. Managing catalog creation and privilege assignment together eliminates the ordering and state-drift problems that arise when they are managed separately.

## When to use

- You are provisioning catalogs in a Unity Catalog-enabled workspace.
- You want a single, repeatable module that handles both catalog creation and initial privilege assignment.
- You need to manage multiple catalogs with different isolation modes or storage roots in a single call.

## When NOT to use

- You need to create schemas, tables, volumes, or external locations — use the appropriate sibling modules (`dbx-uc-schema`, etc.).
- You want to manage grants on securables that already exist and were not created by this module — manage those grants directly at the root composition.
- The catalog already exists and you want to import it — import first, then adopt this module.

## Minimum platform tier

**Premium.** Unity Catalog requires a Premium or higher Databricks platform tier. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier workspace, the API will reject the request and apply will fail. See DATABRICKS_RULES.md Rules 2.3 and 4.1.

## GovCloud notes

This module is cloud-agnostic (workspace-layer only, per DATABRICKS_RULES.md Rule 1.2). It carries no GovCloud-specific parameterization. GovCloud workspace URLs and provider credentials are a root-composition concern passed via the `databricks.workspace` provider.

## Provider configuration

This module uses a single `databricks.workspace` provider alias per DATABRICKS_RULES.md Rule 2.2. The caller must supply a `databricks.workspace` provider configured against the target workspace URL.

```hcl
provider "databricks" {
  alias         = "workspace"
  host          = "https://<workspace-url>"
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "catalogs" {
  source = "git::https://github.com/org/repo.git//modules/dbx-uc-catalog?ref=dbx-uc-catalog/v0.1.0"

  providers = {
    databricks.workspace = databricks.workspace
  }

  metastore_id = var.metastore_id
  catalogs     = var.catalogs
}
```

## Grants behavior

`databricks_grants` is **authoritative**: it replaces the full privilege set on the catalog securable each apply. Any manually added grants not declared in `catalogs[*].grants` will be removed. To preserve externally managed grants, do not include those catalogs in the `grants` list — or manage all grants for those catalogs outside this module.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.39 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.workspace"></a> [databricks.workspace](#provider\_databricks.workspace) | >= 1.39 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_catalog.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/catalog) | resource |
| [databricks_grants.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/grants) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_catalogs"></a> [catalogs](#input\_catalogs) | Map of catalog names to catalog configuration. Each key becomes the catalog name in Unity Catalog.<br/><br/>- comment        : Human-readable description for the catalog. Null omits the field.<br/>- storage\_root   : Fully-qualified cloud storage path (e.g. s3://bucket/prefix) used as the<br/>                   managed storage root. Null uses the metastore default.<br/>- isolation\_mode : Unity Catalog isolation mode. "OPEN" (default) allows any workspace bound<br/>                   to the metastore to access the catalog. "ISOLATED" restricts access to<br/>                   workspaces explicitly bound to the catalog.<br/>- properties     : Arbitrary key-value metadata stored on the catalog object.<br/>- grants         : List of privilege assignments. Each entry specifies a principal (user,<br/>                   group, or service principal) and the list of UC privileges to grant. | <pre>map(object({<br/>    comment        = optional(string, null)<br/>    storage_root   = optional(string, null)<br/>    isolation_mode = optional(string, "OPEN")<br/>    properties     = optional(map(string), {})<br/>    grants = optional(list(object({<br/>      principal  = string<br/>      privileges = list(string)<br/>    })), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_metastore_id"></a> [metastore\_id](#input\_metastore\_id) | ID of the Unity Catalog metastore to which these catalogs belong. Required to scope catalog creation to the correct metastore. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_catalog_ids"></a> [catalog\_ids](#output\_catalog\_ids) | Map of catalog name to the Databricks catalog ID (same as catalog name in UC; exposed for downstream reference and test assertions). |
| <a name="output_catalog_metastore_ids"></a> [catalog\_metastore\_ids](#output\_catalog\_metastore\_ids) | Map of catalog name to the metastore ID the catalog belongs to. Useful for verification. |
| <a name="output_catalog_names"></a> [catalog\_names](#output\_catalog\_names) | Set of catalog names created by this module. Useful for downstream modules that consume catalog names as inputs. |
| <a name="output_catalog_storage_roots"></a> [catalog\_storage\_roots](#output\_catalog\_storage\_roots) | Map of catalog name to the storage root URI. Null for catalogs using the metastore default. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid catalog map creates catalog resources with expected attributes.
- Grants are created only for catalogs with non-empty grants lists.
- Invalid catalog name is rejected by variable validation.
- Invalid isolation_mode is rejected by variable validation.
- Invalid metastore_id format is rejected by variable validation.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks workspace) verifies actual catalog creation and grant assignment. It is credential-gated per DATABRICKS_RULES.md Rule 4.1.
