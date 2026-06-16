# Example: basic

Minimum invocation of the `gcp-account-workspace-storage` module against a GCP project.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your GCP project ID, Databricks account ID, and Databricks-managed service account email.
2. Authenticate to GCP (via `gcloud auth application-default login` or a service account key).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring both `google` and `databricks.account` providers at the root.
- Passing the `databricks.account` provider alias to the module.
- Creating a GCS bucket with default Google-managed encryption (no CMEK).
- Granting the Databricks service account the required IAM roles.
- Registering the bucket as a `databricks_mws_storage_configurations` object.

## Outputs

- `storage_configuration_id` — Pass to a workspace creation module as its `storage_configuration_id` input.
- `bucket_name` — The GCS bucket name (useful for cross-referencing).
- `bucket_url` — The `gs://` URL of the bucket.
