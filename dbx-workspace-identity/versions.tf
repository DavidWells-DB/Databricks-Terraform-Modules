terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.14+: databricks_mws_permission_assignment stable with roles argument
      source                = "databricks/databricks"
      version               = ">= 1.14"
      configuration_aliases = [databricks.account]
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}
