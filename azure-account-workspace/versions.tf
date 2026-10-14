terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azurerm = {
      # 3.76+: enhanced_security_compliance block with compliance_security_profile_standards
      source  = "hashicorp/azurerm"
      version = ">= 3.76"
    }
    azapi = {
      # 2.x: object-style `body` (the compliance azapi_update_resource already uses it)
      # and the azapi_resource data source for the computeMode readback.
      source  = "Azure/azapi"
      version = ">= 2.0"
    }
  }
}
