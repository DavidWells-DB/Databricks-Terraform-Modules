terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azurerm = {
      # 3.75+: azurerm_key_vault purge_protection_enabled + soft_delete_retention_days stable
      source  = "hashicorp/azurerm"
      version = ">= 3.75"
    }
  }
}
