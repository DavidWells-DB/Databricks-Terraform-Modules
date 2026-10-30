terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azurerm = {
      # Still required: the root-DBFS CMK post-creation resource and the parent
      # resource-group lookup (parent_id / managed-resource-group scope).
      # Workspace CREATION no longer uses azurerm — see main.tf for why.
      source  = "hashicorp/azurerm"
      version = ">= 3.76"
    }
    azapi = {
      # 2.x: object-style `body`, `response_export_values` map form, and the
      # 2026-01-01 workspace create with properties.defaultCatalog.
      source  = "Azure/azapi"
      version = ">= 2.0"
    }
  }
}
