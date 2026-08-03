terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azurerm = {
      # 3.75+: azurerm_key_vault purge_protection_enabled + soft_delete_retention_days stable.
      # < 5.0: azurerm 5.x removed private_dns_zone_name from
      # azurerm_private_dns_zone_virtual_network_link; this module targets the 3.x/4.x API.
      source  = "hashicorp/azurerm"
      version = ">= 3.75, < 5.0"
    }
  }
}
