terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azapi = {
      # 2.x: object-style `body` on azapi_resource.
      # azurerm is deliberately absent: it cannot create serverless workspaces
      # (no computeMode argument) and the module needs nothing else from it.
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}
