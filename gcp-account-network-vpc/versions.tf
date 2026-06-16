terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    databricks = {
      # 1.50+: stable gcp_network_info block in databricks_mws_networks on GCP account surface
      source                = "databricks/databricks"
      version               = ">= 1.50"
      configuration_aliases = [databricks.account]
    }
  }
}
