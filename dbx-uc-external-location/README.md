# dbx-uc-external-location

Registers one or more cloud storage paths as Unity Catalog external locations, optionally attaching fine-grained grants to each location.

## What this module abstracts

"A set of named cloud storage paths known to Unity Catalog" — the external location is the unit of storage governance in UC. Each location pairs a cloud storage URL with a storage credential and an optional grant set. This module manages all three concerns together per DATABRICKS_RULES.md Rule 1.4: splitting grants from registration produces thin wrappers.

## When to use

- You need to register one or more S3, ADLS Gen2, or GCS paths as Unity Catalog external locations.
- You want a single declaration that creates the location AND assigns privileges to principals.
- You are bootstrapping UC data access after metastore creation and storage credential registration.

## When NOT to use

- You need to create the storage credential itself — use `azure-uc-storage-credential`, `gcp-uc-storage-credential`, or an equivalent AWS module, then pass the resulting `storage_credential_id` to this module.
- You need to create managed tables inside the location — that is a workspace-layer concern (`dbx-uc-catalog`, `dbx-uc-schema`).

## Minimum platform tier

**Premium.** Unity Catalog external locations require a Premium-tier (or higher) Databricks workspace. The Databricks Terraform provider does not enforce tier at plan time; applying against a Standard-tier workspace will fail at apply time. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

This module uses `databricks.workspace` only (cloud-agnostic). It declares `configuration_aliases = [databricks.workspace]` per DATABRICKS_RULES.md Rule 2.2. The caller must supply a `databricks.workspace` provider configured for the workspace where external locations are registered.

No cloud (AWS/Azure/GCP) provider is required by this module — the cloud credential is already encapsulated in the `storage_credential_id` input.

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
| <a name="provider_databricks.workspace"></a> [databricks.workspace](#provider\_databricks.workspace) | >= 1.50 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_external_location.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/external_location) | resource |
| [databricks_grants.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/grants) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_locations"></a> [locations](#input\_locations) | Map of external location name to configuration. Each key becomes the external location name<br/>registered in Unity Catalog.<br/><br/>Attributes:<br/>  url                   - Cloud storage path (e.g. s3://bucket/prefix, abfss://container@account.dfs.core.windows.net/prefix, gs://bucket/prefix).<br/>  storage\_credential\_id - ID of the databricks\_storage\_credential that grants access to this path.<br/>  comment               - Optional human-readable description attached to the external location.<br/>  read\_only             - When true, the external location is registered as read-only. Defaults to false.<br/>  skip\_validation       - When true, Databricks skips credential validation during creation. Set to true in locked-down environments. Defaults to false.<br/>  grants                - Map of principal → list of privileges. Example: { "data-eng@example.com" = ["READ\_FILES", "WRITE\_FILES"] }. | <pre>map(object({<br/>    url                   = string<br/>    storage_credential_id = string<br/>    comment               = optional(string)<br/>    read_only             = optional(bool, false)<br/>    skip_validation       = optional(bool, false)<br/>    grants                = optional(map(list(string)), {})<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_external_location_ids"></a> [external\_location\_ids](#output\_external\_location\_ids) | Map of external location name to its Databricks resource ID. Useful for referencing locations in downstream resources. |
| <a name="output_external_location_names"></a> [external\_location\_names](#output\_external\_location\_names) | Map of external location name to its registered name in Unity Catalog. Matches the input map keys. |
| <a name="output_external_location_urls"></a> [external\_location\_urls](#output\_external\_location\_urls) | Map of external location name to its cloud storage URL. Useful for verification and downstream configuration. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Single and multi-location inputs are planned with expected attributes.
- Invalid location URL scheme is rejected by variable validation.
- Invalid location name characters are rejected by variable validation.
- Empty `storage_credential_id` is rejected by variable validation.
- Grant blocks are included when grants map is non-empty; omitted when empty.
- `read_only` and `skip_validation` defaults and overrides are verified.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks workspace with Unity Catalog) verifies actual external location creation and grant assignment. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
