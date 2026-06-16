mock_provider "aws" {}

variables {
  bucket_name           = "test-bucket"
  workspace_id          = "1234567890"
  region                = "us-east-1"
  databricks_account_id = "00000000-0000-0000-0000-000000000000"
  aws_partition         = "aws"
  databricks_gov_shard  = null
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
    bucket_name = "this-bucket-name-is-way-too-long-and-exceeds-the-sixty-three-character-limit-for-s3"
  }

  expect_failures = [var.bucket_name]
}

run "bucket_name_invalid_chars_rejected" {
  command = plan

  variables {
    bucket_name = "Invalid_Bucket_Name"
  }

  expect_failures = [var.bucket_name]
}

run "workspace_id_invalid_format_rejected" {
  command = plan

  variables {
    workspace_id = "invalid-workspace-id"
  }

  expect_failures = [var.workspace_id]
}

run "workspace_id_too_short_rejected" {
  command = plan

  variables {
    workspace_id = "123456789"
  }

  expect_failures = [var.workspace_id]
}

run "workspace_id_too_long_rejected" {
  command = plan

  variables {
    workspace_id = "12345678901"
  }

  expect_failures = [var.workspace_id]
}

run "region_invalid_format_rejected" {
  command = plan

  variables {
    region = "invalid-region"
  }

  expect_failures = [var.region]
}

run "databricks_account_id_invalid_format_rejected" {
  command = plan

  variables {
    databricks_account_id = "not-a-uuid"
  }

  expect_failures = [var.databricks_account_id]
}

run "policy_contains_read_actions" {
  command = plan

  assert {
    condition     = can(regex("s3:GetObject", aws_s3_bucket_policy.this.policy))
    error_message = "Policy should contain s3:GetObject action"
  }

  assert {
    condition     = can(regex("s3:ListBucket", aws_s3_bucket_policy.this.policy))
    error_message = "Policy should contain s3:ListBucket action"
  }
}

run "policy_contains_write_actions" {
  command = plan

  assert {
    condition     = can(regex("s3:PutObject", aws_s3_bucket_policy.this.policy))
    error_message = "Policy should contain s3:PutObject action"
  }

  assert {
    condition     = can(regex("s3:DeleteObject", aws_s3_bucket_policy.this.policy))
    error_message = "Policy should contain s3:DeleteObject action"
  }
}

run "policy_contains_ephemeral_path" {
  command = plan

  assert {
    condition     = can(regex("ephemeral/us-east-1-prod/1234567890/", aws_s3_bucket_policy.this.policy))
    error_message = "Policy should contain workspace-specific ephemeral path"
  }
}

run "policy_contains_warehouse_path" {
  command = plan

  assert {
    condition     = can(regex("user/hive/warehouse/", aws_s3_bucket_policy.this.policy))
    error_message = "Policy should contain user/hive/warehouse path"
  }
}

run "policy_contains_filestore_path" {
  command = plan

  assert {
    condition     = can(regex("FileStore/", aws_s3_bucket_policy.this.policy))
    error_message = "Policy should contain FileStore path"
  }
}

run "policy_contains_principal_tag_condition" {
  command = plan

  assert {
    condition     = can(regex("aws:PrincipalTag/DatabricksAccountId", aws_s3_bucket_policy.this.policy))
    error_message = "Policy should contain principal tag condition"
  }
}

run "policy_contains_ssl_enforcement" {
  command = plan

  assert {
    condition     = can(regex("aws:SecureTransport", aws_s3_bucket_policy.this.policy))
    error_message = "Policy should contain SSL enforcement (aws:SecureTransport condition)"
  }

  assert {
    condition     = can(regex("\"Effect\"\\s*:\\s*\"Deny\"", aws_s3_bucket_policy.this.policy))
    error_message = "Policy should contain Deny effect for SSL enforcement"
  }
}

run "bucket_policy_references_correct_bucket" {
  command = plan

  assert {
    condition     = aws_s3_bucket_policy.this.bucket == "test-bucket"
    error_message = "Bucket policy should reference the correct bucket name"
  }
}
