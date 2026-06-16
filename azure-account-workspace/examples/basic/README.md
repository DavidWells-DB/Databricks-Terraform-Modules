# Example: basic

Minimum invocation of the `azure-account-workspace` module. Creates a premium Azure Databricks workspace without VNet injection, CMK, or compliance settings.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Azure subscription ID, resource group name, and desired workspace name.
2. Ensure the resource group already exists in your subscription (this example does not create it).
3. Log in to Azure with `az login` or set `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID` environment variables.
4. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring `azurerm` and `azapi` providers at the root.
- Creating a premium workspace with minimum required inputs.
- Consuming `workspace_url` from the module output for downstream provider configuration.

## Outputs

- `workspace_id` — Databricks numeric workspace ID.
- `workspace_url` — Workspace URL (`https://adb-...azuredatabricks.net`). Pass as `host` to the workspace-scoped Databricks provider.
- `workspace_resource_id` — Azure ARM resource ID for RBAC and policy assignments.
