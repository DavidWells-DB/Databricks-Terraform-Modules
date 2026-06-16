# Example: basic

Minimum invocation of the `dbx-uc-metastore-assignment` module. Assigns a Unity Catalog metastore to two workspaces (prod and dev) without setting a default catalog.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks account ID, service principal credentials, metastore ID, and workspace IDs.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring both `databricks.account` and `databricks.workspace` provider aliases at the root and passing them to the module.
- Assigning a single metastore to multiple workspaces in one module call.
- Using the default (`null`) for `default_catalog_name` — no default catalog is configured.

## Outputs

- `assignment_ids` — Map of labels to metastore assignment IDs. Pass to downstream modules that need proof of assignment.
- `assigned_workspace_ids` — Map of labels to numeric workspace IDs for cross-referencing.
