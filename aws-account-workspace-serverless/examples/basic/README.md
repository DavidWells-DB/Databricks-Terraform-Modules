# Example: basic

Minimum invocation of the `aws-account-workspace-serverless` module against a commercial Databricks account.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks account ID and service principal credentials.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks.account` provider at the root composition level.
- Passing the `databricks.account` provider alias to the module.
- A minimal serverless workspace with no VPC, no IAM role, and no DBFS storage configuration.

## Outputs

- `workspace_id` — Pass to workspace-scoped modules (e.g. Unity Catalog setup) as their `workspace_id` input.
- `workspace_url` — Use as the `host` for the workspace-scoped Databricks provider after provisioning.
