terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc_peering" {
  source = "../.."

  requester_vpc_id          = var.requester_vpc_id
  accepter_vpc_id           = var.accepter_vpc_id
  requester_vpc_cidr        = var.requester_vpc_cidr
  accepter_vpc_cidr         = var.accepter_vpc_cidr
  requester_route_table_ids = var.requester_route_table_ids
  accepter_route_table_ids  = var.accepter_route_table_ids
  accepter_account_id       = var.accepter_account_id
  accepter_region           = var.aws_region
  peering_name              = "databricks-to-shared-services"

  tags = {
    Module  = "aws-account-network-vpc-peering"
    Example = "basic"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for both VPCs (same-region peering in this example)."
  default     = "us-east-1"
}

variable "requester_vpc_id" {
  type        = string
  description = "VPC ID of the Databricks data-plane VPC (requester side)."
}

variable "accepter_vpc_id" {
  type        = string
  description = "VPC ID of the hub or shared-services VPC (accepter side)."
}

variable "requester_vpc_cidr" {
  type        = string
  description = "CIDR block of the Databricks data-plane VPC."
}

variable "accepter_vpc_cidr" {
  type        = string
  description = "CIDR block of the hub or shared-services VPC."
}

variable "requester_route_table_ids" {
  type        = list(string)
  description = "Route table IDs in the Databricks data-plane VPC (requester side)."
}

variable "accepter_route_table_ids" {
  type        = list(string)
  description = "Route table IDs in the hub or shared-services VPC (accepter side)."
}

variable "accepter_account_id" {
  type        = string
  description = "AWS account ID of the accepter VPC owner. Use your own account ID for same-account peering."
}

output "peering_connection_id" {
  description = "ID of the established VPC peering connection."
  value       = module.vpc_peering.peering_connection_id
}

output "peering_connection_status" {
  description = "Status of the VPC peering connection."
  value       = module.vpc_peering.peering_connection_status
}
