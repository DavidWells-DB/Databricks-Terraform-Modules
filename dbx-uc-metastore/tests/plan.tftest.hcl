mock_provider "databricks" {
  alias = "account"

  mock_resource "databricks_metastore" {
    defaults = {
      id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    }
  }

  mock_resource "databricks_metastore_data_access" {
    defaults = {
      id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee|example-data-access"
    }
  }
}

variables {
  metastore_name   = "test-metastore"
  region           = "us-east-1"
  storage_root_url = "s3://my-uc-bucket/metastore"
  data_access_name = "test-data-access"
  storage_credential = {
    aws_iam_role = {
      role_arn = "arn:aws:iam::123456789012:role/test-uc-role"
    }
  }
}

run "metastore_resource_uses_input_name" {
  command = plan

  assert {
    condition     = databricks_metastore.this.name == "test-metastore"
    error_message = "Metastore name should match the metastore_name input"
  }
}

run "metastore_resource_uses_input_region" {
  command = plan

  assert {
    condition     = databricks_metastore.this.region == "us-east-1"
    error_message = "Metastore region should match the region input"
  }
}

run "metastore_resource_uses_input_storage_root" {
  command = plan

  assert {
    condition     = databricks_metastore.this.storage_root == "s3://my-uc-bucket/metastore"
    error_message = "Metastore storage_root should match the storage_root_url input"
  }
}

run "data_access_is_default" {
  command = plan

  assert {
    condition     = databricks_metastore_data_access.this.is_default == true
    error_message = "data_access is_default should always be true"
  }
}

run "data_access_uses_input_name" {
  command = plan

  assert {
    condition     = databricks_metastore_data_access.this.name == "test-data-access"
    error_message = "Data access name should match the data_access_name input"
  }
}

run "metastore_name_empty_rejected" {
  command = plan

  variables {
    metastore_name = ""
  }

  expect_failures = [var.metastore_name]
}

run "metastore_name_leading_whitespace_rejected" {
  command = plan

  variables {
    metastore_name = " leading-space"
  }

  expect_failures = [var.metastore_name]
}

run "region_empty_rejected" {
  command = plan

  variables {
    region = ""
  }

  expect_failures = [var.region]
}

run "region_with_spaces_rejected" {
  command = plan

  variables {
    region = "us east 1"
  }

  expect_failures = [var.region]
}

run "storage_root_url_invalid_scheme_rejected" {
  command = plan

  variables {
    storage_root_url = "https://mybucket/metastore"
  }

  expect_failures = [var.storage_root_url]
}

run "storage_root_url_plain_bucket_rejected" {
  command = plan

  variables {
    storage_root_url = "mybucket/metastore"
  }

  expect_failures = [var.storage_root_url]
}

run "storage_root_url_s3_accepted" {
  command = plan

  variables {
    storage_root_url = "s3://valid-bucket/prefix"
  }

  assert {
    condition     = databricks_metastore.this.storage_root == "s3://valid-bucket/prefix"
    error_message = "s3:// URL should be accepted"
  }
}

run "storage_root_url_abfss_accepted" {
  command = plan

  variables {
    storage_root_url = "abfss://container@account.dfs.core.windows.net/prefix"
  }

  assert {
    condition     = databricks_metastore.this.storage_root == "abfss://container@account.dfs.core.windows.net/prefix"
    error_message = "abfss:// URL should be accepted"
  }
}

run "storage_root_url_gs_accepted" {
  command = plan

  variables {
    storage_root_url = "gs://my-gcs-bucket/metastore"
  }

  assert {
    condition     = databricks_metastore.this.storage_root == "gs://my-gcs-bucket/metastore"
    error_message = "gs:// URL should be accepted"
  }
}

run "data_access_name_empty_rejected" {
  command = plan

  variables {
    data_access_name = ""
  }

  expect_failures = [var.data_access_name]
}

run "owner_group_leading_whitespace_rejected" {
  command = plan

  variables {
    owner_group = " bad-group"
  }

  expect_failures = [var.owner_group]
}

run "owner_group_null_accepted" {
  command = plan

  variables {
    owner_group = null
  }

  assert {
    condition     = databricks_metastore.this.name == "test-metastore"
    error_message = "null owner_group should be accepted without error"
  }
}

run "storage_credential_no_block_rejected" {
  command = plan

  variables {
    storage_credential = {
      aws_iam_role                   = null
      azure_managed_identity         = null
      databricks_gcp_service_account = null
    }
  }

  expect_failures = [var.storage_credential]
}

run "storage_credential_multiple_blocks_rejected" {
  command = plan

  variables {
    storage_credential = {
      aws_iam_role = {
        role_arn = "arn:aws:iam::123456789012:role/test-role"
      }
      azure_managed_identity = {
        access_connector_id = "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Databricks/accessConnectors/ac"
      }
    }
  }

  expect_failures = [var.storage_credential]
}
