# Example: basic

Minimum invocation of the `azure-uc-storage-credential` module against an Azure subscription.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Azure and Databricks values.
2. Ensure the Azure CLI or service principal credentials are available to the `azurerm` provider.
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring both `azurerm` and `databricks.workspace` providers at the root.
- Passing the `databricks.workspace` provider alias to the module.
- Using the auto-derived `access_connector_name` (no explicit name supplied).

## Outputs

- `access_connector_id` — Full Azure resource ID of the created Access Connector.
- `access_connector_principal_id` — Object ID of the SystemAssigned managed identity (useful for additional RBAC assignments).
- `storage_credential_id` — Databricks UC storage credential ID; pass to `databricks_external_location` or metastore data access.
