mock_provider "aws" {}

mock_provider "databricks" {
  alias = "account"

  override_data {
    target = data.databricks_aws_bucket_policy.this
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::414351767826:root\"},\"Action\":\"s3:*\",\"Resource\":[\"arn:aws:s3:::test-bucket\",\"arn:aws:s3:::test-bucket/*\"]}]}"
    }
  }
}

variables {
  databricks_account_id      = "00000000-0000-0000-0000-000000000000"
  aws_partition              = "aws"
  databricks_gov_shard       = null
  bucket_name                = "test-databricks-root-bucket"
  storage_configuration_name = "test-storage"
}

run "commercial_shard_uses_commercial_account_id" {
  command = plan

  assert {
    condition     = output.databricks_aws_account_id == "414351767826"
    error_message = "Commercial shard should resolve to Databricks AWS account ID 414351767826"
  }
}

run "civilian_shard_uses_civilian_account_id" {
  command = plan

  variables {
    aws_partition        = "aws-us-gov"
    databricks_gov_shard = "civilian"
  }

  assert {
    condition     = output.databricks_aws_account_id == "044793339203"
    error_message = "GovCloud civilian shard should resolve to Databricks AWS account ID 044793339203"
  }
}

run "dod_shard_uses_dod_account_id" {
  command = plan

  variables {
    aws_partition        = "aws-us-gov"
    databricks_gov_shard = "dod"
  }

  assert {
    condition     = output.databricks_aws_account_id == "170661010020"
    error_message = "GovCloud DoD shard should resolve to Databricks AWS account ID 170661010020"
  }
}

run "invalid_aws_partition_rejected" {
  command = plan

  variables {
    aws_partition = "invalid-partition"
  }

  expect_failures = [var.aws_partition]
}

run "invalid_gov_shard_rejected" {
  command = plan

  variables {
    databricks_gov_shard = "invalid-shard"
  }

  expect_failures = [var.databricks_gov_shard]
}

run "bucket_name_too_short_rejected" {
  command = plan

  variables {
    bucket_name = "ab"
  }

  expect_failures = [var.bucket_name]
}

run "bucket_name_too_long_rejected" {
  command = plan

  variables {
    bucket_name = "this-bucket-name-is-way-too-long-and-exceeds-the-s3-sixty-three-character-maximum-limit"
  }

  expect_failures = [var.bucket_name]
}

run "bucket_name_uppercase_rejected" {
  command = plan

  variables {
    bucket_name = "Invalid-Uppercase-Bucket"
  }

  expect_failures = [var.bucket_name]
}

run "bucket_name_starts_with_hyphen_rejected" {
  command = plan

  variables {
    bucket_name = "-invalid-start"
  }

  expect_failures = [var.bucket_name]
}

run "storage_configuration_name_empty_rejected" {
  command = plan

  variables {
    storage_configuration_name = ""
  }

  expect_failures = [var.storage_configuration_name]
}

run "storage_configuration_name_invalid_chars_rejected" {
  command = plan

  variables {
    storage_configuration_name = "invalid name with spaces"
  }

  expect_failures = [var.storage_configuration_name]
}

run "bucket_name_matches_input" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket == "test-databricks-root-bucket"
    error_message = "S3 bucket name should match the bucket_name input"
  }
}

run "public_access_blocked" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "block_public_acls should be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_policy == true
    error_message = "block_public_policy should be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.ignore_public_acls == true
    error_message = "ignore_public_acls should be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.restrict_public_buckets == true
    error_message = "restrict_public_buckets should be true"
  }
}

run "sse_s3_used_without_kms_key" {
  command = plan

  assert {
    # rule is a set; use tolist + one() to retrieve the sole element safely.
    condition     = one(tolist(aws_s3_bucket_server_side_encryption_configuration.this.rule)).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "SSE algorithm should be AES256 when kms_key_arn is not set"
  }
}

run "sse_kms_used_with_kms_key" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    # rule is a set; use tolist + one() to retrieve the sole element safely.
    condition     = one(tolist(aws_s3_bucket_server_side_encryption_configuration.this.rule)).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "SSE algorithm should be aws:kms when kms_key_arn is set"
  }
}
