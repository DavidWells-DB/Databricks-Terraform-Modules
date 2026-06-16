terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azurerm = {
      # 3.75+: stable azurerm_subnet delegation support for Databricks VNet injection
      # (Microsoft.Databricks/workspaces service delegation on host + container subnets)
      source  = "hashicorp/azurerm"
      version = ">= 3.75"
    }
  }
}
