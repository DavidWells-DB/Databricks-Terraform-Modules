# Example: basic

Minimum invocation of the `dbx-workspace-secret-scope` module. Creates two Databricks-native secret scopes:

- `app-secrets` — grants initial MANAGE permission to all workspace users.
- `infra-secrets` — grants MANAGE only to the calling principal (default behavior).

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your workspace URL and service principal credentials.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks.workspace` provider at the root and passing it to the module.
- Using `initial_manage_principal = "users"` on one scope and omitting it on another.
- Consuming the `scope_names` and `scope_backend_types` outputs.

## Outputs

- `scope_names` — Set of created scope names.
- `scope_backend_types` — Map of scope name to backend type (`DATABRICKS` for native scopes).
