terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    databricks = {
      # 1.50+: stable databricks_mws_vpc_endpoint GCP PSC support and databricks_mws_private_access_settings
      source                = "databricks/databricks"
      version               = ">= 1.50"
      configuration_aliases = [databricks.account]
    }
  }
}
