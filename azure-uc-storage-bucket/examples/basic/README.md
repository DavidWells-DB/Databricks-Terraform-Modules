# Example: basic

Minimum invocation of the `azure-uc-storage-bucket` module — a dedicated ADLS Gen2 storage account + private container for a Unity Catalog catalog's managed storage.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in the resource group, location, and a globally unique storage account name (3-24 chars, lowercase alphanumeric).
2. Configure Azure credentials (`ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`, `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`).
3. Run:

   ```
   terraform init
   terraform apply
   ```

4. Outputs: `storage_root` (the `abfss://…dfs.core.windows.net` Unity Catalog root) and `storage_account_id` (feeds `azure-uc-storage-credential`'s `storage_account_id`).

## Clean-up

```
terraform destroy
```
