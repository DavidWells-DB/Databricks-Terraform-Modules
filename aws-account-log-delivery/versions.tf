terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    databricks = {
      # 1.50+: stable databricks_mws_log_delivery, databricks_mws_credentials,
      # databricks_mws_storage_configurations, and GovCloud account host support
      source                = "databricks/databricks"
      version               = ">= 1.50"
      configuration_aliases = [databricks.account]
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}
