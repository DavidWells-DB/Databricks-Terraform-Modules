terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azurerm = {
      # 3.50+: azurerm_storage_account with hierarchical namespace (ADLS Gen2) support stable
      source  = "hashicorp/azurerm"
      version = ">= 3.50"
    }
  }
}
