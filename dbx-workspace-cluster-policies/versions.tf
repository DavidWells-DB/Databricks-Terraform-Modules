terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.14+: databricks_cluster_policy policy_family_id + policy_family_definition_overrides support
      source                = "databricks/databricks"
      version               = ">= 1.14"
      configuration_aliases = [databricks.workspace]
    }
  }
}
