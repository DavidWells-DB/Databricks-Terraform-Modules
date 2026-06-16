# Basic Example

Applies a restrictive S3 bucket policy to an existing Databricks workspace root storage bucket.

## Prerequisites

- An existing Databricks workspace with a root storage bucket
- The workspace ID (10-digit numeric string)
- AWS credentials with permissions to update S3 bucket policies

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Fill in the required values:
   - `bucket_name`: The workspace's root storage bucket name (e.g., `databricks-workspace-12345678`)
   - `workspace_id`: The 10-digit Databricks workspace ID
   - `databricks_account_id`: Your Databricks account ID (UUID format)
3. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## What this example does

1. Applies a restrictive S3 bucket policy that:
   - Allows read access to the entire bucket
   - Restricts write access to workspace-specific paths: `ephemeral/{region}-prod/{workspace_id}/*`, `user/hive/warehouse/*`, `FileStore/*`
   - Enforces principal tag condition: `aws:PrincipalTag/DatabricksAccountId` equals the Databricks account ID
   - Denies non-HTTPS access

## Verification

After applying, verify the policy is in place:

```bash
aws s3api get-bucket-policy --bucket <bucket_name> --query Policy --output text | jq .
```

You should see the restrictive policy with scoped write paths and SSL enforcement.
