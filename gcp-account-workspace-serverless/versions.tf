terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.50+: stable databricks_mws_workspaces behavior on GCP with compute_mode = "SERVERLESS"
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
