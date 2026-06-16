terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azurerm = {
      # 3.0+: azurerm_virtual_network_peering stable API and allow_forwarded_traffic support
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}
