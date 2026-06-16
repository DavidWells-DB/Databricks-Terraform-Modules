# Example: basic

Minimum invocation of the `aws-account-encryption-keys` module against a commercial AWS account.

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

- Configuring both `aws` and `databricks.account` providers at the root.
- Passing the `databricks.account` provider alias to the module.
- Using `data "aws_caller_identity"` to supply the AWS account ID dynamically.
- Using the module defaults for a commercial (non-GovCloud) deployment.

## Outputs

- `managed_services_key_id` — Pass as `managed_services_customer_managed_key_id` to a workspace creation module.
- `workspace_storage_key_id` — Pass as `storage_customer_managed_key_id` to a workspace creation module.
- `managed_services_key_arn` — ARN of the managed-services KMS key.
- `workspace_storage_key_arn` — ARN of the workspace-storage KMS key.
