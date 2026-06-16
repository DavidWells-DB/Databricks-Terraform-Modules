mock_provider "aws" {
  override_data {
    target = data.aws_iam_policy_document.managed_services
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.workspace_storage
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

mock_provider "databricks" {
  alias = "account"
}

variables {
  databricks_account_id       = "00000000-0000-0000-0000-000000000000"
  aws_account_id              = "123456789012"
  aws_partition               = "aws"
  databricks_gov_shard        = null
  cross_account_role_arn      = "arn:aws:iam::123456789012:role/databricks-cross-account"
  managed_services_key_alias  = "alias/databricks-managed-services"
  workspace_storage_key_alias = "alias/databricks-workspace-storage"
}

run "commercial_shard_uses_commercial_control_plane_account_id" {
  command = plan

  assert {
    condition     = output.databricks_control_plane_aws_account_id == "414351767826"
    error_message = "Commercial shard should resolve to Databricks AWS account ID 414351767826"
  }
}

run "civilian_shard_uses_civilian_control_plane_account_id" {
  command = plan

  variables {
    aws_partition        = "aws-us-gov"
    databricks_gov_shard = "civilian"
  }

  assert {
    condition     = output.databricks_control_plane_aws_account_id == "044793339203"
    error_message = "GovCloud civilian shard should resolve to Databricks AWS account ID 044793339203"
  }
}

run "dod_shard_uses_dod_control_plane_account_id" {
  command = plan

  variables {
    aws_partition        = "aws-us-gov"
    databricks_gov_shard = "dod"
  }

  assert {
    condition     = output.databricks_control_plane_aws_account_id == "170661010020"
    error_message = "GovCloud DoD shard should resolve to Databricks AWS account ID 170661010020"
  }
}

run "managed_services_key_alias_matches_input" {
  command = plan

  assert {
    condition     = aws_kms_alias.managed_services.name == "alias/databricks-managed-services"
    error_message = "Managed-services KMS alias should match the managed_services_key_alias input"
  }
}

run "workspace_storage_key_alias_matches_input" {
  command = plan

  assert {
    condition     = aws_kms_alias.workspace_storage.name == "alias/databricks-workspace-storage"
    error_message = "Workspace-storage KMS alias should match the workspace_storage_key_alias input"
  }
}

run "managed_services_cmk_use_case_is_managed_services" {
  command = plan

  assert {
    condition     = contains(tolist(databricks_mws_customer_managed_keys.managed_services.use_cases), "MANAGED_SERVICES")
    error_message = "Managed-services CMK use_cases should contain MANAGED_SERVICES"
  }
}

run "workspace_storage_cmk_use_case_is_storage" {
  command = plan

  assert {
    condition     = contains(tolist(databricks_mws_customer_managed_keys.workspace_storage.use_cases), "STORAGE")
    error_message = "Workspace-storage CMK use_cases should contain STORAGE"
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
    aws_account_id = "12345"
  }

  expect_failures = [var.aws_account_id]
}

run "aws_account_id_with_letters_rejected" {
  command = plan

  variables {
    aws_account_id = "12345678901a"
  }

  expect_failures = [var.aws_account_id]
}

run "invalid_cross_account_role_arn_rejected" {
  command = plan

  variables {
    cross_account_role_arn = "not-an-arn"
  }

  expect_failures = [var.cross_account_role_arn]
}

run "managed_services_alias_missing_prefix_rejected" {
  command = plan

  variables {
    managed_services_key_alias = "databricks-managed-services"
  }

  expect_failures = [var.managed_services_key_alias]
}

run "workspace_storage_alias_missing_prefix_rejected" {
  command = plan

  variables {
    workspace_storage_key_alias = "databricks-workspace-storage"
  }

  expect_failures = [var.workspace_storage_key_alias]
}
