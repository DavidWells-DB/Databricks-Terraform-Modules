mock_provider "aws" {}

mock_provider "time" {}

mock_provider "databricks" {
  alias = "account"

  override_data {
    target = data.databricks_aws_assume_role_policy.this
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::414351767826:root\"},\"Action\":\"sts:AssumeRole\",\"Condition\":{\"StringEquals\":{\"sts:ExternalId\":\"00000000-0000-0000-0000-000000000000\"}}}]}"
    }
  }

  override_data {
    target = data.databricks_aws_bucket_policy.this
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::test-role\"},\"Action\":[\"s3:GetObject\",\"s3:PutObject\"],\"Resource\":\"arn:aws:s3:::test-prefix-log-delivery/*\"}]}"
    }
  }
}

variables {
  databricks_account_id = "00000000-0000-0000-0000-000000000000"
  aws_partition         = "aws"
  databricks_gov_shard  = null
  resource_prefix       = "test-prefix"
}

# ---------------------------------------------------------------------------
# gov_shard branching
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Variable validation — aws_partition
# ---------------------------------------------------------------------------

run "invalid_aws_partition_rejected" {
  command = plan

  variables {
    aws_partition = "invalid-partition"
  }

  expect_failures = [var.aws_partition]
}

# ---------------------------------------------------------------------------
# Variable validation — databricks_gov_shard
# ---------------------------------------------------------------------------

run "invalid_gov_shard_rejected" {
  command = plan

  variables {
    databricks_gov_shard = "invalid-shard"
  }

  expect_failures = [var.databricks_gov_shard]
}

# ---------------------------------------------------------------------------
# Variable validation — resource_prefix
# ---------------------------------------------------------------------------

run "resource_prefix_too_long_rejected" {
  command = plan

  variables {
    resource_prefix = "this-prefix-is-way-too-long-and-exceeds-the-thirty-two-character-cap"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_invalid_chars_rejected" {
  command = plan

  variables {
    resource_prefix = "invalid prefix with spaces"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_empty_rejected" {
  command = plan

  variables {
    resource_prefix = ""
  }

  expect_failures = [var.resource_prefix]
}

# ---------------------------------------------------------------------------
# Variable validation — log_types
# ---------------------------------------------------------------------------

run "log_types_invalid_value_rejected" {
  command = plan

  variables {
    log_types = ["AUDIT_LOGS", "INVALID_TYPE"]
  }

  expect_failures = [var.log_types]
}

run "log_types_empty_list_rejected" {
  command = plan

  variables {
    log_types = []
  }

  expect_failures = [var.log_types]
}

# ---------------------------------------------------------------------------
# Resource naming — AWS resources use resource_prefix
# ---------------------------------------------------------------------------

run "s3_bucket_name_uses_prefix" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket == "test-prefix-log-delivery"
    error_message = "S3 bucket name should be <resource_prefix>-log-delivery"
  }
}

run "iam_role_name_uses_prefix" {
  command = plan

  assert {
    condition     = aws_iam_role.this.name == "test-prefix-log-delivery"
    error_message = "IAM role name should be <resource_prefix>-log-delivery"
  }
}

# ---------------------------------------------------------------------------
# for_each — log_types drives one delivery config per type
# ---------------------------------------------------------------------------

run "both_log_types_creates_two_delivery_configs" {
  command = plan

  variables {
    log_types = ["AUDIT_LOGS", "BILLABLE_USAGE"]
  }

  assert {
    condition     = length(databricks_mws_log_delivery.this) == 2
    error_message = "Two log_types should produce two databricks_mws_log_delivery resources"
  }
}

run "single_log_type_creates_one_delivery_config" {
  command = plan

  variables {
    log_types = ["AUDIT_LOGS"]
  }

  assert {
    condition     = length(databricks_mws_log_delivery.this) == 1
    error_message = "One log_type should produce one databricks_mws_log_delivery resource"
  }
}

run "audit_logs_delivery_path_prefix" {
  command = plan

  variables {
    log_types = ["AUDIT_LOGS"]
  }

  assert {
    condition     = databricks_mws_log_delivery.this["AUDIT_LOGS"].delivery_path_prefix == "audit-logs"
    error_message = "AUDIT_LOGS delivery_path_prefix should be 'audit-logs'"
  }
}

run "billable_usage_delivery_path_prefix" {
  command = plan

  variables {
    log_types = ["BILLABLE_USAGE"]
  }

  assert {
    condition     = databricks_mws_log_delivery.this["BILLABLE_USAGE"].delivery_path_prefix == "billable-usage"
    error_message = "BILLABLE_USAGE delivery_path_prefix should be 'billable-usage'"
  }
}
