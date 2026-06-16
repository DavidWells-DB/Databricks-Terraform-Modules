terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.14+: databricks_secret_scope stable; keyvault_metadata for Azure Key Vault-backed scopes
      source                = "databricks/databricks"
      version               = ">= 1.14"
      configuration_aliases = [databricks.workspace]
    }
  }
}
