terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.81.0+: databricks_workspace_network_option introduced in this release
      source  = "databricks/databricks"
      version = ">= 1.81.0"
      # All resources here (NCC binding, private-endpoint rule, workspace network option)
      # are account-surface, so only databricks.account is required.
      configuration_aliases = [databricks.account]
    }
  }
}
