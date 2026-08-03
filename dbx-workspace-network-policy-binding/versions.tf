terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.81.0+: databricks_workspace_network_option introduced in this release.
      # This resource is account-surface ("can only be used with an account-level
      # provider" — provider docs), so only databricks.account is required.
      source                = "databricks/databricks"
      version               = ">= 1.81.0"
      configuration_aliases = [databricks.account]
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}
