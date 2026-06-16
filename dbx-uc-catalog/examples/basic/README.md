# Example: basic

Minimum invocation of the `dbx-uc-catalog` module, demonstrating two catalogs:

- `analytics` — with a comment, `OPEN` isolation mode, custom properties, and initial privilege grants to two groups.
- `sandbox` — a no-grant catalog for exploratory use.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your workspace URL, service principal credentials, and metastore ID.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks.workspace` provider at the root.
- Passing the `databricks.workspace` provider alias to the module.
- Mixing catalogs with and without grants in the same call.
- Using `isolation_mode = "OPEN"` (the default).

## Outputs

- `catalog_ids` — Map of catalog name to catalog ID; pass to downstream schema or grant modules.
- `catalog_names` — Set of catalog names; useful for data source lookups.
