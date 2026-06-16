# Example: basic

Minimum invocation of the `aws-account-log-delivery` module against a commercial AWS account, delivering both audit logs and billable usage logs to S3.

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
- Using the module's defaults for a commercial (non-GovCloud) deployment with both `AUDIT_LOGS` and `BILLABLE_USAGE` log types.

## Outputs

- `bucket_name` — Name of the S3 bucket receiving log files.
- `role_arn` — ARN of the IAM role Databricks uses to write to the bucket.
- `log_delivery_configuration_ids` — Map of log type (`AUDIT_LOGS`, `BILLABLE_USAGE`) to Databricks log delivery configuration ID.
