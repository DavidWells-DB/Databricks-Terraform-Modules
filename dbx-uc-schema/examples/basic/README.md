# Example: basic

Minimum invocation of the `dbx-uc-schema` module, demonstrating two schemas:

- `raw` — with a comment, custom properties, and initial privilege grants to a group.
- `curated` — a no-grant schema for cleaned datasets.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your workspace URL, service principal credentials, and catalog name.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks.workspace` provider at the root.
- Passing the `databricks.workspace` provider alias to the module.
- Mixing schemas with and without grants in the same call.
- Using the catalog default storage root (no `storage_root` set).

## Outputs

- `schema_ids` — Map of schema name to schema ID; pass to downstream grant or table modules.
- `schema_names` — Set of schema names; useful for data source lookups.
