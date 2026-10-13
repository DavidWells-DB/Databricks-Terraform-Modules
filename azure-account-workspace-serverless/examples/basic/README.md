# Example: basic

Minimum invocation of the `azure-account-workspace-serverless` module against a commercial Azure subscription.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Azure subscription ID and resource group.
2. Ensure Azure credentials are configured (via `az login`, service principal environment variables `ARM_*`, or managed identity).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `azapi` provider at the root — the module creates the workspace via the ARM API, because `azurerm_databricks_workspace` cannot express `computeMode = "Serverless"`.
- Creating a true serverless workspace: all workloads run on serverless compute, with managed default storage and Unity Catalog enabled automatically.
- Deriving the module's `resource_group_id` input from the subscription ID and resource group name.

## Outputs

- `workspace_id` — Numeric Databricks workspace ID; pass to workspace-scoped modules.
- `workspace_url` — Full HTTPS workspace URL; use as the host for the workspace-scoped Databricks provider.
- `workspace_resource_id` — Azure ARM resource ID; use for RBAC assignments and private endpoint wiring.
