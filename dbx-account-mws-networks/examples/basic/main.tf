terraform {
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

variable "databricks_account_id" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }

module "registration" {
  source = ".."

  providers = { databricks.account = databricks.account }

  databricks_account_id = var.databricks_account_id
  network_name          = "my-workspace-network"
  vpc_id                = var.vpc_id
  private_subnet_ids    = var.private_subnet_ids
  security_group_ids    = var.security_group_ids
}
