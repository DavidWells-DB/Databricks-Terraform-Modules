mock_provider "aws" {}

mock_provider "databricks" {
  alias = "account"

  override_data {
    target = data.databricks_aws_assume_role_policy.this
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::414351767826:root\"},\"Action\":\"sts:AssumeRole\"}]}"
    }
  }

  override_data {
    target = data.databricks_aws_crossaccount_policy.this
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"ec2:*\",\"Resource\":\"*\"}]}"
    }
  }
}

variables {
  databricks_account_id = "00000000-0000-0000-0000-000000000000"
  aws_partition         = "aws"
  databricks_gov_shard  = null
  role_name             = "test-role"
  credentials_name      = "test-creds"
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

run "role_resource_uses_input_name" {
  command = plan

  assert {
    condition     = aws_iam_role.this.name == "test-role"
    error_message = "IAM role name should match the role_name input"
  }
}

run "role_policy_named_with_suffix" {
  command = plan

  assert {
    condition     = aws_iam_role_policy.this.name == "test-role-policy"
    error_message = "IAM role policy name should be <role_name>-policy"
  }
}

run "role_name_too_long_rejected" {
  command = plan

  variables {
    role_name = "this-role-name-is-way-too-long-and-exceeds-the-aws-iam-sixty-four-character-cap"
  }

  expect_failures = [var.role_name]
}

run "role_name_invalid_chars_rejected" {
  command = plan

  variables {
    role_name = "invalid name with spaces"
  }

  expect_failures = [var.role_name]
}

run "credentials_name_empty_rejected" {
  command = plan

  variables {
    credentials_name = ""
  }

  expect_failures = [var.credentials_name]
}

run "credentials_name_invalid_chars_rejected" {
  command = plan

  variables {
    credentials_name = "invalid name with spaces"
  }

  expect_failures = [var.credentials_name]
}
