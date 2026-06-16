# dbx-uc-schema

Creates Unity Catalog schemas within a catalog, with optional managed storage location and privilege grants per schema.

## What this module abstracts

"The schema layer of a Unity Catalog hierarchy" — a cohesive operational unit. The module creates one or more `databricks_schema` resources via `for_each` and, for each schema that declares grants, one authoritative `databricks_grants` resource. Managing schema creation and privilege assignment together eliminates the ordering and state-drift problems that arise when they are managed separately.

## When to use

- You are provisioning schemas inside an existing Unity Catalog catalog.
- You want a single, repeatable module that handles both schema creation and initial privilege assignment.
- You need to manage multiple schemas with different storage roots or grant configurations in a single call.

## When NOT to use

- You need to create the catalog itself — use the `dbx-uc-catalog` module.
- You need to create tables, volumes, or external locations — use the appropriate sibling modules.
- You want to manage grants on schemas that already exist and were not created by this module — manage those grants directly at the root composition.
- The schema already exists and you want to import it — import first, then adopt this module.

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

module "schemas" {
  source = "git::https://github.com/org/repo.git//modules/dbx-uc-schema?ref=dbx-uc-schema/v0.1.0"

  providers = {
    databricks.workspace = databricks.workspace
  }

  catalog_name = var.catalog_name
  schemas      = var.schemas
}
```

## Grants behavior

`databricks_grants` is **authoritative**: it replaces the full privilege set on the schema securable each apply. Any manually added grants not declared in `schemas[*].grants` will be removed. To preserve externally managed grants, do not include those schemas in the `grants` list — or manage all grants for those schemas outside this module.

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
| [databricks_grants.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/grants) | resource |
| [databricks_schema.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/schema) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_catalog_name"></a> [catalog\_name](#input\_catalog\_name) | Name of the Unity Catalog catalog in which schemas are created. Must already exist. | `string` | n/a | yes |
| <a name="input_schemas"></a> [schemas](#input\_schemas) | Map of schema names to schema configuration. Each key becomes the schema name in Unity Catalog.<br/><br/>- comment      : Human-readable description for the schema. Null omits the field.<br/>- storage\_root : Fully-qualified cloud storage path (e.g. s3://bucket/prefix/schema) used as<br/>                 the managed storage root for tables in this schema. Null uses the catalog default.<br/>- properties   : Arbitrary key-value metadata stored on the schema object.<br/>- grants       : List of privilege assignments. Each entry specifies a principal (user,<br/>                 group, or service principal) and the list of UC privileges to grant.<br/>                 databricks\_grants is authoritative: it replaces the full privilege set each apply. | <pre>map(object({<br/>    comment      = optional(string, null)<br/>    storage_root = optional(string, null)<br/>    properties   = optional(map(string), {})<br/>    grants = optional(list(object({<br/>      principal  = string<br/>      privileges = list(string)<br/>    })), [])<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_catalog_name"></a> [catalog\_name](#output\_catalog\_name) | Name of the catalog in which schemas were created. Useful for constructing fully-qualified names downstream. |
| <a name="output_schema_ids"></a> [schema\_ids](#output\_schema\_ids) | Map of schema name to the Databricks schema ID (same as schema name in UC; exposed for downstream reference and test assertions). |
| <a name="output_schema_names"></a> [schema\_names](#output\_schema\_names) | Set of schema names created by this module. Useful for downstream modules that consume schema names as inputs. |
| <a name="output_schema_storage_roots"></a> [schema\_storage\_roots](#output\_schema\_storage\_roots) | Map of schema name to the storage root URI. Null for schemas using the catalog default. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid schema map creates schema resources with expected attributes.
- Grants are created only for schemas with non-empty grants lists.
- Invalid schema name is rejected by variable validation.
- Invalid catalog_name format is rejected by variable validation.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks workspace) verifies actual schema creation and grant assignment. It is credential-gated per DATABRICKS_RULES.md Rule 4.1.
