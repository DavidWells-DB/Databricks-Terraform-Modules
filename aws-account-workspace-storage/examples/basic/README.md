# Example: basic

Minimum invocation of the `aws-account-workspace-storage` module against a commercial AWS account.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks account ID, service principal credentials, and a globally unique S3 bucket name.
2. Configure AWS credentials for the target account (via environment variables, profile, or IAM role).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring both `aws` and `databricks.account` providers at the root.
- Passing the `databricks.account` provider alias to the module.
- Using the module's defaults for a commercial (non-GovCloud) deployment with SSE-S3 encryption.

## Outputs

- `storage_configuration_id` — Pass to a workspace creation module as its `storage_configuration_id` input.
- `bucket_name` — The S3 bucket name (useful for cross-referencing).
- `bucket_arn` — The S3 bucket ARN (useful for IAM policy construction).
