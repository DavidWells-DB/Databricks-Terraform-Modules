terraform {
  required_version = ">= 1.7.0"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.81"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

provider "aws" {
  region = "us-east-1"
}

variable "databricks_account_id" { type = string }
variable "metastore_id" { type = string }
variable "aws_account_id" { type = string }

module "root_credential" {
  source = "../.."

  providers = { databricks.account = databricks.account }

  metastore_id    = var.metastore_id
  credential_name = "metastore-root"
  role_name       = "my-metastore-uc-role"
  bucket_name     = "my-metastore-root-bucket"
  aws_account_id  = var.aws_account_id
}
