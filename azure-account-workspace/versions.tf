terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azurerm = {
      # 3.76+: enhanced_security_compliance block with compliance_security_profile_standards
      source  = "hashicorp/azurerm"
      version = ">= 3.76"
    }
    azapi = {
      # 1.9+: stable azapi_update_resource with ignore_missing_property behavior
      source  = "Azure/azapi"
      version = ">= 1.9"
    }
  }
}
