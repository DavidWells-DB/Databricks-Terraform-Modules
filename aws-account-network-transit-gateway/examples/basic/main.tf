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

module "transit_gateway" {
  source = "../.."

  resource_prefix = var.resource_prefix
  tgw_asn         = var.tgw_asn
  vpc_attachments = var.vpc_attachments

  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Module  = "aws-account-network-transit-gateway"
    Example = "basic"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for the provider."
  default     = "us-east-1"
}

variable "resource_prefix" {
  type        = string
  description = "Short prefix applied to Transit Gateway and route table names."
}

variable "tgw_asn" {
  type        = number
  description = "Private BGP ASN for the Transit Gateway (64512-65534 or 4200000000-4294967294)."
  default     = 64512
}

variable "vpc_attachments" {
  type = map(object({
    vpc_id     = string
    subnet_ids = list(string)
  }))
  description = "Map of attachment name to VPC and subnet IDs to attach to the Transit Gateway."
}

output "transit_gateway_id" {
  description = "ID of the created Transit Gateway."
  value       = module.transit_gateway.transit_gateway_id
}

output "attachment_ids" {
  description = "Map of VPC attachment name to attachment ID."
  value       = module.transit_gateway.attachment_ids
}

output "route_table_id" {
  description = "ID of the shared Transit Gateway route table."
  value       = module.transit_gateway.route_table_id
}
