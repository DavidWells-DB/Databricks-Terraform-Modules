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

module "vpc_endpoints" {
  source = "../.."

  vpc_id                  = var.vpc_id
  region                  = var.aws_region
  private_subnet_ids      = var.private_subnet_ids
  security_group_ids      = var.security_group_ids
  private_route_table_ids = var.private_route_table_ids
  databricks_gov_shard    = null

  tags = {
    Module  = "aws-account-network-vpc-endpoints"
    Example = "basic"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for the provider and endpoint service names."
  default     = "us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "ID of the existing VPC in which to create the VPC endpoints."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the STS and Kinesis interface endpoints."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs to associate with the STS and Kinesis interface endpoints."
}

variable "private_route_table_ids" {
  type        = list(string)
  description = "Route table IDs to associate with the S3 gateway endpoint."
}

output "s3_endpoint_id" {
  description = "ID of the S3 gateway VPC endpoint."
  value       = module.vpc_endpoints.s3_endpoint_id
}

output "sts_endpoint_id" {
  description = "ID of the STS interface VPC endpoint."
  value       = module.vpc_endpoints.sts_endpoint_id
}

output "kinesis_endpoint_id" {
  description = "ID of the Kinesis Streams interface VPC endpoint."
  value       = module.vpc_endpoints.kinesis_endpoint_id
}
