# Example: basic

Minimum invocation of the `dbx-uc-metastore` module against a commercial AWS Databricks account.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks account credentials, S3 root URL, and IAM role ARN.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring a `databricks.account` provider at the root and passing it to the module.
- Providing an AWS IAM role as the storage credential via the `storage_credential.aws_iam_role` block.
- Using the module to create a metastore with a default data access configuration in a single step.

## Outputs

- `metastore_id` — Pass to `dbx-uc-metastore-assignment` as its `metastore_id` input.
- `metastore_name` — Display name of the created metastore.
