terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.39+: stable databricks_ip_access_list and databricks_workspace_conf behavior
      source                = "databricks/databricks"
      version               = ">= 1.39"
      configuration_aliases = [databricks.workspace]
    }
  }
}
