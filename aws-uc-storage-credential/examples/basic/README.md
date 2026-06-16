# Example: basic

Minimum invocation of the `aws-uc-storage-credential` module against a commercial AWS account and an existing Databricks Unity Catalog workspace.

## Prerequisites

- An existing S3 bucket to register with Unity Catalog.
- A Databricks workspace with a Unity Catalog metastore assigned (Premium tier or higher).
- A workspace-level service principal with Metastore Admin or Storage Credential Create privilege.
- AWS credentials with IAM admin access to the target account.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values.
2. Configure AWS credentials for the target account (via environment variables, profile, or IAM role).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring both the `aws` and `databricks.workspace` providers at the root.
- Passing the `databricks.workspace` provider alias to the module.
- Using commercial (non-GovCloud) defaults.
- The two-apply pattern: on the first apply, `databricks_storage_credential` is created with `skip_validation = true` and the IAM role is then created with the correct trust policy. On subsequent applies, the trust relationship is validated by Databricks.

## Outputs

- `storage_credential_id` — Pass to an `aws-uc-external-location` module or a `databricks_external_location` resource.
- `iam_role_arn` — The AWS IAM role ARN (useful for cross-referencing in IAM consoles or policy audits).
- `external_id` — The Databricks-generated confused-deputy external ID embedded in the IAM trust policy.
