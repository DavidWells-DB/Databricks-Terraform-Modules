# Example: basic

Minimum invocation of the `dbx-workspace-network-policy-binding` module. Binds an existing account network policy to a workspace.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks account ID, service principal credentials, workspace ID, and the network policy ID to bind.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks.account` provider at the root and passing the alias to the module.
- Binding a standalone account network policy to a workspace via `databricks_workspace_network_option`.

## Outputs

- `binding_id` — composite `<workspace_id>|<network_policy_id>` identifier for the binding.
- `network_policy_id` — the policy ID bound to the workspace.
