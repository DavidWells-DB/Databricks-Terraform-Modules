# Example: basic

Minimum invocation of the `azure-account-workspace-storage` module for a Databricks Unity Catalog metastore or workspace root on Azure.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Azure subscription ID, resource group name, and resource prefix.
2. Ensure `az login` or service principal credentials are configured for the target subscription.
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `azurerm` provider at the root.
- Creating ADLS Gen2 storage with a custom prefix and LRS replication.
- Using the module defaults: `Standard` tier, `TLS1_2`, public access blocked, HNS enabled.
- No CMK (Microsoft-managed keys). Add `kms_key_id` to enable CMK for IL5 / Azure Government.

## Outputs

- `storage_account_name` — Pass to a UC metastore or access connector role assignment module.
- `storage_account_id` — Use for RBAC role assignments (Storage Blob Data Contributor for the Access Connector).
- `container_name` — The container (filesystem) name inside the storage account.
- `dfs_endpoint` — The DFS endpoint URL; used as the UC external location root path.
