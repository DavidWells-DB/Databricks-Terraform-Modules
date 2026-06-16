terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    databricks = {
      # 1.50+: stable databricks_storage_credential aws_iam_role external_id attribute
      # and GovCloud aws_partition support in databricks_aws_unity_catalog_assume_role_policy
      source                = "databricks/databricks"
      version               = ">= 1.50"
      configuration_aliases = [databricks.workspace]
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}
