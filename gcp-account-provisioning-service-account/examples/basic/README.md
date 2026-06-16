# Example: basic

Minimum invocation of the `gcp-account-provisioning-service-account` module against a GCP project.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your GCP project ID and Databricks account ID.
2. Configure GCP credentials (via `gcloud auth application-default login`, a service account key, or Workload Identity).
3. Set Databricks OAuth credentials via environment variables:
   ```
   export DATABRICKS_CLIENT_ID=<account-service-principal-id>
   export DATABRICKS_CLIENT_SECRET=<account-service-principal-secret>
   ```
4. Run:
   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring both `google` and `databricks.account` providers at the root composition.
- Passing the `databricks.account` provider alias to the module.
- Using the module's default `resource_prefix = "example"` for a minimal deployment.

## Outputs

- `service_account_email` — The provisioner service account email; reference this in workspace provisioning modules.
- `custom_role_id` — The fully-qualified custom IAM role name; useful for cross-referencing or extending permissions.
- `databricks_user_id` — The Databricks account user ID; useful for additional Databricks grants.
