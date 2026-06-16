mock_provider "aws" {}

mock_provider "databricks" {
  alias = "workspace"

  override_data {
    target = data.databricks_aws_unity_catalog_assume_role_policy.this
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL\"},\"Action\":\"sts:AssumeRole\",\"Condition\":{\"StringEquals\":{\"sts:ExternalId\":\"mock-external-id\"}}}]}"
    }
  }

  override_data {
    target = data.databricks_aws_unity_catalog_policy.this
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"s3:GetObject\",\"s3:PutObject\",\"s3:DeleteObject\",\"s3:ListBucket\",\"s3:GetBucketLocation\"],\"Resource\":[\"arn:aws:s3:::test-bucket\",\"arn:aws:s3:::test-bucket/*\"]}]}"
    }
  }

  override_resource {
    target = databricks_storage_credential.this
    values = {
      id                    = "test-storage-cred"
      storage_credential_id = "abc123-storage-credential-id"
      name                  = "test-storage-cred"
      aws_iam_role = {
        role_arn              = "arn:aws:iam::123456789012:role/test-uc-role"
        external_id           = "mock-external-id"
        unity_catalog_iam_arn = "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
      }
    }
  }
}

mock_provider "time" {}

variables {
  credential_name      = "test-storage-cred"
  role_name            = "test-uc-role"
  bucket_name          = "test-bucket"
  aws_account_id       = "123456789012"
  aws_partition        = "aws"
  databricks_gov_shard = null
}

run "commercial_shard_uses_commercial_uc_iam_arn" {
  command = plan

  assert {
    condition     = output.unity_catalog_iam_arn == "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
    error_message = "Commercial shard should resolve to the commercial Databricks UC master role ARN"
  }
}

run "civilian_shard_uses_civilian_uc_iam_arn" {
  command = plan

  variables {
    aws_partition        = "aws-us-gov"
    databricks_gov_shard = "civilian"
  }

  assert {
    condition     = output.unity_catalog_iam_arn == "arn:aws-us-gov:iam::044793339203:role/unity-catalog-prod-UCMasterRole-1QRFA8SGY15OJ"
    error_message = "GovCloud civilian shard should resolve to the civilian Databricks UC master role ARN"
  }
}

run "dod_shard_uses_dod_uc_iam_arn" {
  command = plan

  variables {
    aws_partition        = "aws-us-gov"
    databricks_gov_shard = "dod"
  }

  assert {
    condition     = output.unity_catalog_iam_arn == "arn:aws-us-gov:iam::170661010020:role/unity-catalog-prod-UCMasterRole-1DI6DL6ZP26AS"
    error_message = "GovCloud DoD shard should resolve to the DoD Databricks UC master role ARN"
  }
}

run "invalid_aws_partition_rejected" {
  command = plan

  variables {
    aws_partition = "aws-cn"
  }

  expect_failures = [var.aws_partition]
}

run "invalid_gov_shard_rejected" {
  command = plan

  variables {
    databricks_gov_shard = "fedramp"
  }

  expect_failures = [var.databricks_gov_shard]
}

run "invalid_aws_account_id_rejected" {
  command = plan

  variables {
    aws_account_id = "1234"
  }

  expect_failures = [var.aws_account_id]
}

run "aws_account_id_with_letters_rejected" {
  command = plan

  variables {
    aws_account_id = "12345678901A"
  }

  expect_failures = [var.aws_account_id]
}

run "bucket_name_too_short_rejected" {
  command = plan

  variables {
    bucket_name = "ab"
  }

  expect_failures = [var.bucket_name]
}

run "bucket_name_uppercase_rejected" {
  command = plan

  variables {
    bucket_name = "MyBucket"
  }

  expect_failures = [var.bucket_name]
}

run "role_name_too_long_rejected" {
  command = plan

  variables {
    role_name = "this-role-name-is-way-too-long-and-exceeds-the-aws-iam-sixty-four-character-cap"
  }

  expect_failures = [var.role_name]
}

run "role_name_spaces_rejected" {
  command = plan

  variables {
    role_name = "invalid role name"
  }

  expect_failures = [var.role_name]
}

run "credential_name_empty_rejected" {
  command = plan

  variables {
    credential_name = ""
  }

  expect_failures = [var.credential_name]
}

run "credential_name_spaces_rejected" {
  command = plan

  variables {
    credential_name = "invalid credential name"
  }

  expect_failures = [var.credential_name]
}

run "invalid_isolation_mode_rejected" {
  command = plan

  variables {
    isolation_mode = "ISOLATION_MODE_UNKNOWN"
  }

  expect_failures = [var.isolation_mode]
}

run "iam_role_uses_input_name" {
  command = plan

  assert {
    condition     = aws_iam_role.this.name == "test-uc-role"
    error_message = "IAM role name should match the role_name input"
  }
}

run "iam_role_policy_named_with_suffix" {
  command = plan

  assert {
    condition     = aws_iam_role_policy.this.name == "test-uc-role-uc-policy"
    error_message = "IAM role policy name should be <role_name>-uc-policy"
  }
}

run "storage_credential_uses_input_name" {
  command = plan

  assert {
    condition     = databricks_storage_credential.this.name == "test-storage-cred"
    error_message = "Storage credential name should match the credential_name input"
  }
}
