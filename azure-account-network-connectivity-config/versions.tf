terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.50+: databricks_mws_network_connectivity_config and databricks_account_network_policy
      # are stable at this version for Azure serverless private connectivity.
      source                = "databricks/databricks"
      version               = ">= 1.50"
      configuration_aliases = [databricks.account]
    }
  }
}
