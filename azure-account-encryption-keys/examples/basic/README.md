# Example: basic

Minimum invocation of the `azure-account-encryption-keys` module — creates a Key Vault with three Databricks CMK keys, no private endpoint.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Azure subscription ID, tenant ID, resource group, and object IDs.
2. Ensure your Azure CLI or service principal credentials are configured.
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `azurerm` provider at the root with subscription and tenant.
- Passing all required inputs to the module (no private endpoint).
- The module's default `soft_delete_retention_days = 7` (minimum allowed).

## Outputs

- `key_vault_id` — Pass to `azurerm_databricks_workspace` as `managed_services_cmk_key_vault_id` and `managed_disk_cmk_key_vault_id`.
- `managed_services_key_id` — Pass to `azurerm_databricks_workspace` as `managed_services_cmk_key_vault_key_id`.
- `workspace_storage_key_id` — Pass to `azurerm_databricks_workspace_root_dbfs_customer_managed_key`.
- `managed_disk_key_id` — Pass to `azurerm_databricks_workspace` as `managed_disk_cmk_key_vault_key_id`.
