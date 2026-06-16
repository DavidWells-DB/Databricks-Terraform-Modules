terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.60+: databricks_account_network_policy resource introduced
      source                = "databricks/databricks"
      version               = ">= 1.60"
      configuration_aliases = [databricks.account]
    }
  }
}
