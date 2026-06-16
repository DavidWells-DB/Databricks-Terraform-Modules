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

module "privatelink_endpoints" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  databricks_gov_shard = null # commercial; set to "civilian" or "dod" for GovCloud

  vpc_id                 = var.vpc_id
  privatelink_subnet_ids = var.privatelink_subnet_ids
  region                 = var.aws_region

  private_access_settings_name = "example-pas"
  workspace_vpc_endpoint_name  = "example-workspace-vpce"
  relay_vpc_endpoint_name      = "example-relay-vpce"

  security_group_name                = "example-privatelink-sg"
  security_group_ingress_cidr_blocks = var.security_group_ingress_cidr_blocks

  public_access_enabled = true # also allow public access alongside PrivateLink
  private_access_level  = "ACCOUNT"

  enable_service_direct = false

  tags = {
    Module  = "aws-account-network-privatelink-endpoints"
    Example = "basic"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for the provider and endpoint lookup."
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

variable "vpc_id" {
  type        = string
  description = "ID of the AWS VPC in which to create the PrivateLink endpoints."
}

variable "privatelink_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the PrivateLink endpoint ENIs. One per AZ recommended."
}

variable "security_group_ingress_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks permitted to reach the PrivateLink endpoints. Typically the VPC CIDR and workspace subnet CIDRs."
  default     = ["10.0.0.0/8"]
}

output "workspace_vpc_endpoint_id" {
  description = "Databricks vpc_endpoint_id for the workspace REST API endpoint."
  value       = module.privatelink_endpoints.workspace_vpc_endpoint_id
}

output "relay_vpc_endpoint_id" {
  description = "Databricks vpc_endpoint_id for the SCC relay endpoint."
  value       = module.privatelink_endpoints.relay_vpc_endpoint_id
}

output "private_access_settings_id" {
  description = "Databricks private_access_settings_id to pass to the workspace creation module."
  value       = module.privatelink_endpoints.private_access_settings_id
}

output "security_group_id" {
  description = "ID of the AWS security group for the PrivateLink endpoints."
  value       = module.privatelink_endpoints.security_group_id
}

output "workspace_service_name" {
  description = "Resolved AWS endpoint service name for the workspace endpoint (for verification)."
  value       = module.privatelink_endpoints.workspace_service_name
}
