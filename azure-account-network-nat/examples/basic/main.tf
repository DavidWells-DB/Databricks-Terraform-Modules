terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70"
    }
  }
}

provider "azurerm" {
  features {}
}

module "nat" {
  source = "../.."

  resource_group_name = var.resource_group_name
  location            = var.location

  nat_gateway_name = "databricks-nat"
  public_ip_name   = "databricks-nat-ip"

  # Map of caller-chosen names to subnet resource IDs (typically outputs of the
  # azure-account-network-vnet module consumed in the same apply).
  subnets = {
    host      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/databricks-vnet/subnets/databricks-host"
    container = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/databricks-vnet/subnets/databricks-container"
  }

  tags = {
    Module  = "azure-account-network-nat"
    Example = "basic"
  }
}

variable "resource_group_name" {
  type    = string
  default = "rg-databricks-test"
}

variable "location" {
  type    = string
  default = "eastus"
}
