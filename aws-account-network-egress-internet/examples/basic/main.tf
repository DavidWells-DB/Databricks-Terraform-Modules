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

module "egress_internet" {
  source = "../.."

  vpc_id                  = var.vpc_id
  public_subnet_ids       = var.public_subnet_ids
  private_route_table_ids = var.private_route_table_ids
  nat_gateway_count       = 1

  tags = {
    Module  = "aws-account-network-egress-internet"
    Example = "basic"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for the provider."
  default     = "us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "ID of the existing VPC in which to create internet egress resources."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs into which the NAT Gateway is placed."
}

variable "private_route_table_ids" {
  type        = list(string)
  description = "List of private route table IDs to receive the 0.0.0.0/0 → NAT Gateway route."
}

output "internet_gateway_id" {
  value = module.egress_internet.internet_gateway_id
}

output "nat_gateway_id" {
  value = module.egress_internet.nat_gateway_id
}

output "nat_public_ip" {
  value = module.egress_internet.nat_public_ip
}
