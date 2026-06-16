# Example: basic

Minimum invocation of the `dbx-workspace-identity` module. Assigns two account-level groups to an existing workspace — one as USER, one as ADMIN.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks account ID, service principal credentials, workspace ID, and group principal IDs.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks.account` provider at the root and passing it to the module.
- Using the `assignments` map to assign multiple principals in a single module call.
- Assigning a group as USER and a group as ADMIN in the same invocation.

## Outputs

- `assignment_ids` — Map of assignment label to Databricks permission assignment ID. Useful for verification and downstream dependencies.
