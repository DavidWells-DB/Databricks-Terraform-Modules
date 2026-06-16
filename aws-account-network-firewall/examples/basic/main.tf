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

module "network_firewall" {
  source = "../.."

  vpc_id              = var.vpc_id
  firewall_name       = var.firewall_name
  firewall_subnet_ids = var.firewall_subnet_ids

  private_route_table_ids = var.private_route_table_ids

  # No rule groups in the basic example — firewall is deployed in pass-through mode
  # (all traffic forwarded to stateful engine by default). Add rule group ARNs here
  # once you have created them with aws_networkfirewall_rule_group resources.
  stateful_rule_group_arns  = []
  stateless_rule_group_arns = []

  stateless_default_actions          = ["aws:forward_to_sfe"]
  stateless_fragment_default_actions = ["aws:forward_to_sfe"]

  tags = {
    Module  = "aws-account-network-firewall"
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
  description = "ID of the VPC in which to deploy the Network Firewall."
}

variable "firewall_name" {
  type        = string
  description = "Name for the Network Firewall and its policy."
  default     = "databricks-egress-firewall"
}

variable "firewall_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the firewall endpoints (one per AZ)."
}

variable "private_route_table_ids" {
  type        = list(string)
  description = "Private route table IDs that will receive 0.0.0.0/0 → firewall routes."
}

output "firewall_id" {
  description = "ID of the created Network Firewall."
  value       = module.network_firewall.firewall_id
}

output "firewall_arn" {
  description = "ARN of the created Network Firewall."
  value       = module.network_firewall.firewall_arn
}

output "firewall_policy_arn" {
  description = "ARN of the Network Firewall policy."
  value       = module.network_firewall.firewall_policy_arn
}
