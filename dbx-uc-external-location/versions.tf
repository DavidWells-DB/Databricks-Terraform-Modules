terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.50+: stable databricks_external_location and databricks_grants on workspace surface
      source                = "databricks/databricks"
      version               = ">= 1.50"
      configuration_aliases = [databricks.workspace]
    }
  }
}
