terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75"
    }
    databricks = {
      # 1.49+: stable databricks_storage_credential with azure_managed_identity support
      source                = "databricks/databricks"
      version               = ">= 1.49"
      configuration_aliases = [databricks.workspace]
    }
  }
}
