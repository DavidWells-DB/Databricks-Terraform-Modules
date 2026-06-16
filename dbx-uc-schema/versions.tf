terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.39+: databricks_schema managed_location and stable databricks_grants behavior
      source                = "databricks/databricks"
      version               = ">= 1.39"
      configuration_aliases = [databricks.workspace]
    }
  }
}
