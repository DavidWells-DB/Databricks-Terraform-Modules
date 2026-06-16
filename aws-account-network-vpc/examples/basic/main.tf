terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.50"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "databricks" {
  alias         = "account"
  host          = var.databricks_account_host
  account_id    = var.databricks_account_id
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "network_vpc" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id = var.databricks_account_id
  databricks_gov_shard  = null

  resource_prefix = var.resource_prefix
  network_name    = "${var.resource_prefix}-network"

  vpc_cidr = "10.0.0.0/16"

  azs = [
    "${var.aws_region}a",
    "${var.aws_region}b",
  ]

  private_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24",
  ]

  # Public subnets are optional; populate to support aws-account-network-egress-internet.
  public_subnet_cidrs = [
    "10.0.101.0/24",
    "10.0.102.0/24",
  ]

  # vpc_endpoint_ids omitted — no PrivateLink in this basic example.

  tags = {
    Module  = "aws-account-network-vpc"
    Example = "basic"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for the provider."
  default     = "us-east-1"
}

variable "databricks_account_host" {
  type        = string
  description = "Databricks account host. Commercial: https://accounts.cloud.databricks.com. GovCloud civilian: https://accounts.cloud.databricks.us. DoD: https://accounts-dod.cloud.databricks.mil."
  default     = "https://accounts.cloud.databricks.com"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID."
}

variable "databricks_client_id" {
  type        = string
  description = "Databricks account-level service principal application ID (OAuth M2M)."
}

variable "databricks_client_secret" {
  type        = string
  description = "Databricks account-level service principal secret (OAuth M2M)."
  sensitive   = true
}

variable "resource_prefix" {
  type        = string
  description = "Prefix used to name all created AWS resources."
  default     = "databricks-example"
}

output "vpc_id" {
  value = module.network_vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.network_vpc.private_subnet_ids
}

output "security_group_id" {
  value = module.network_vpc.security_group_id
}

output "databricks_network_id" {
  value = module.network_vpc.databricks_network_id
}

output "private_route_table_ids" {
  value = module.network_vpc.private_route_table_ids
}
