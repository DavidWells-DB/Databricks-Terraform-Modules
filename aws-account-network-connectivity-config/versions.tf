terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.50+: databricks_mws_network_connectivity_config stable support and GovCloud account host support
      source                = "databricks/databricks"
      version               = ">= 1.50"
      configuration_aliases = [databricks.account]
    }
  }
}
