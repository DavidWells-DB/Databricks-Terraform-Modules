# Example: basic

Minimum invocation of the `aws-account-workspace-credentials` module against a commercial AWS account.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks account ID and service principal credentials.
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
- Using the module's defaults for a commercial (non-GovCloud) deployment.

## Outputs

- `credentials_id` — Pass to a workspace creation module as its `credentials_id` input.
- `role_arn` — The AWS IAM role's ARN (useful for cross-referencing).
