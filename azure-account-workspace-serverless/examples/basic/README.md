# Example: basic

Minimum invocation of the `azure-account-workspace-serverless` module against a commercial Azure subscription.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Azure subscription ID and resource group.
2. Ensure Azure credentials are configured (via `az login`, service principal environment variables, or managed identity).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `azurerm` provider at the root with `features {}` and `subscription_id`.
- Creating a serverless-only workspace (no VNet injection, no `custom_parameters`).
- Using the module's default `sku = "premium"` (required for serverless compute).

## Outputs

- `workspace_id` — Numeric Databricks workspace ID; pass to workspace-scoped modules.
- `workspace_url` — Full HTTPS workspace URL; use as the host for the workspace-scoped Databricks provider.
- `workspace_resource_id` — Azure ARM resource ID; use for RBAC assignments and private endpoint wiring.
