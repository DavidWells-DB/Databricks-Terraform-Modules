terraform {
  required_version = ">= 1.7"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.81"
    }
  }
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

module "ncc_private_endpoint_rules" {
  source = "../../"

  providers = {
    databricks.account = databricks.account
  }

  network_connectivity_config_id = var.network_connectivity_config_id
  cloud                          = "aws"
  private_endpoint_rules         = var.private_endpoint_rules
}
