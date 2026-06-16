terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    azurerm = {
      # 3.75+: azurerm_firewall_policy_rule_collection_group and azurerm_ip_group are
      # stable; azurerm_firewall with firewall_policy_id (detached policy) is stable.
      source  = "hashicorp/azurerm"
      version = ">= 3.75"
    }
  }
}
