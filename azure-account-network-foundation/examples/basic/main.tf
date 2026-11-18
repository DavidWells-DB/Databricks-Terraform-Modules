terraform {
  required_version = ">= 1.7.0"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.81"
    }
  }
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.azuredatabricks.net"
  account_id = var.databricks_account_id
}

variable "databricks_account_id" { type = string }
variable "region" { type = string }

module "foundation" {
  source = "../.."

  providers = { databricks.account = databricks.account }

  databricks_account_id = var.databricks_account_id
  region                = var.region
  ncc_name              = "serverless-ncc"
}
