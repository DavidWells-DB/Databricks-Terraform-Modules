# Integration test: applies restrictive bucket policy to a real S3 bucket.
# Requires:
# - AWS credentials with s3:PutBucketPolicy permission
# - An existing S3 bucket (created outside this test)
# - Databricks account ID (for principal tag condition)
#
# Usage:
#   export TF_VAR_test_bucket_name="your-test-bucket"
#   export TF_VAR_test_workspace_id="1234567890"
#   export TF_VAR_test_region="us-east-1"
#   export TF_VAR_test_databricks_account_id="00000000-0000-0000-0000-000000000000"
#   terraform test -filter=tests/integration.tftest.hcl

variable "test_bucket_name" {
  type        = string
  description = "Name of an existing S3 bucket to test against."
}

variable "test_workspace_id" {
  type        = string
  description = "Databricks workspace ID for testing."
}

variable "test_region" {
  type        = string
  description = "AWS region for testing."
}

variable "test_databricks_account_id" {
  type        = string
  description = "Databricks account ID for testing."
}

variables {
  bucket_name           = var.test_bucket_name
  workspace_id          = var.test_workspace_id
  region                = var.test_region
  databricks_account_id = var.test_databricks_account_id
  aws_partition         = "aws"
  databricks_gov_shard  = null
}

run "apply_restrictive_policy" {
  command = apply

  assert {
    condition     = output.bucket_name == var.test_bucket_name
    error_message = "Output bucket_name should match input"
  }

  assert {
    condition     = output.bucket_policy_id == var.test_bucket_name
    error_message = "bucket_policy_id should equal bucket name"
  }

  assert {
    condition     = output.databricks_aws_account_id == "414351767826"
    error_message = "Commercial shard should resolve to 414351767826"
  }
}
