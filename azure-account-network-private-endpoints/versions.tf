terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azurerm = {
      # 3.63+: azurerm_private_dns_zone_virtual_network_link `registration_enabled` GA
      source  = "hashicorp/azurerm"
      version = ">= 3.63"
    }
  }
}
