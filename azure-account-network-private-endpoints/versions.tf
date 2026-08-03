terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azurerm = {
      # 3.63+: azurerm_private_dns_zone_virtual_network_link `registration_enabled` GA.
      # < 5.0: azurerm 5.x removed private_dns_zone_name + resource_group_name from
      # azurerm_private_dns_zone_virtual_network_link; this module targets the 3.x/4.x API.
      source  = "hashicorp/azurerm"
      version = ">= 3.63, < 5.0"
    }
  }
}
