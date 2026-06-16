# Example: basic

Minimum invocation of the `gcp-uc-storage-credential` module against an existing GCS bucket and a Databricks workspace on GCP.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your GCP project, bucket name, and Databricks workspace credentials.
2. Ensure the Google credentials in your environment have `storage.buckets.setIamPolicy` on the target bucket.
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring both `google` and `databricks.workspace` providers at the root.
- Passing the `databricks.workspace` provider alias to the module.
- Creating a Databricks-managed GCP service account storage credential paired with GCS IAM bindings.

## Outputs

- `storage_credential_id` — Pass to `databricks_external_location` as its `credential_name` input.
- `databricks_service_account_email` — The Databricks-managed GCP service account email; use to grant additional GCP IAM roles if needed.
