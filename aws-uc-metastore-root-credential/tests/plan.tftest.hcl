mock_provider "databricks" {
  alias = "account"

  mock_resource "databricks_metastore_data_access" {
    defaults = {
      id = "metastore-id|credential-name"
    }
  }

  mock_data "databricks_aws_unity_catalog_policy" {
    defaults = {
      json = "{}"
    }
  }

  mock_data "databricks_aws_unity_catalog_assume_role_policy" {
    defaults = {
      json = "{}"
    }
  }
}

mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::111122223333:role/my-role"
      id  = "my-role"
    }
  }
  mock_resource "aws_iam_role_policy" {
    defaults = {
      id = "my-role-policy"
    }
  }
}

variables {
  metastore_id    = "01234567-89ab-cdef-0123-456789abcdef"
  credential_name = "metastore-root"
  role_name       = "my-role"
  bucket_name     = "my-bucket"
  aws_account_id  = "111122223333"
}

run "data_access_binds_to_the_given_metastore" {
  command = plan

  assert {
    condition     = databricks_metastore_data_access.this.metastore_id == "01234567-89ab-cdef-0123-456789abcdef"
    error_message = "The credential must register against the GIVEN metastore (the account-plane fix — never a workspace-scoped auto-assigned one)"
  }

  assert {
    condition     = databricks_metastore_data_access.this.is_default == true
    error_message = "The root-storage credential must be the metastore default"
  }
}

run "role_arn_is_precomputed_from_account_and_name" {
  command = plan

  assert {
    condition     = databricks_metastore_data_access.this.aws_iam_role[0].role_arn == "arn:aws:iam::111122223333:role/my-role"
    error_message = "The credential is created FIRST with the pre-computed role ARN (the circular-dependency choreography)"
  }
}

run "trust_policy_uses_the_data_access_external_id" {
  command = apply

  assert {
    condition     = data.databricks_aws_unity_catalog_assume_role_policy.this.external_id == databricks_metastore_data_access.this.aws_iam_role[0].external_id
    error_message = "The IAM trust must be built from THIS credential's external_id (the wrong-metastore fix)"
  }
}

run "iam_role_created_with_the_trust_policy" {
  command = plan

  assert {
    condition     = aws_iam_role.this.name == "my-role" && aws_iam_role_policy.this.role == "my-role"
    error_message = "The role + policy pair must follow the credential"
  }
}

run "invalid_metastore_id_rejected" {
  command = plan

  variables {
    metastore_id = "not-a-uuid"
  }

  expect_failures = [var.metastore_id]
}

run "invalid_aws_account_id_rejected" {
  command = plan

  variables {
    aws_account_id = "12345"
  }

  expect_failures = [var.aws_account_id]
}

run "invalid_partition_rejected" {
  command = plan

  variables {
    aws_partition = "aws-cn"
  }

  expect_failures = [var.aws_partition]
}
