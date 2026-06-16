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

module "serverless_privatelink" {
  source = "../.."

  name                  = "databricks-serverless-pl"
  vpc_id                = var.vpc_id
  subnet_ids            = var.subnet_ids
  target_ip             = var.target_ip
  target_port           = var.target_port
  listener_port         = var.listener_port
  databricks_account_id = var.databricks_account_id
  aws_partition         = "aws"
  databricks_gov_shard  = null

  tags = {
    Module  = "aws-account-network-serverless-privatelink"
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
  description = "VPC ID where resources will be created."
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the Network Load Balancer."
}

variable "target_ip" {
  type        = string
  description = "IP address of the target resource (e.g., RDS endpoint IP)."
}

variable "target_port" {
  type        = number
  description = "Port on the target resource."
  default     = 5432
}

variable "listener_port" {
  type        = number
  description = "NLB listener port. Defaults to target_port if not specified."
  default     = null
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID."
}

output "endpoint_service_name" {
  value       = module.serverless_privatelink.endpoint_service_name
  description = "VPC endpoint service name to provide to Databricks."
}

output "nlb_dns_name" {
  value       = module.serverless_privatelink.nlb_dns_name
  description = "DNS name of the Network Load Balancer."
}

output "nlb_arn" {
  value       = module.serverless_privatelink.nlb_arn
  description = "ARN of the Network Load Balancer."
}
