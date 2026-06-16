variable "name" {
  type        = string
  description = "Resource naming prefix. Used to name the NLB, target group, security group, and VPC endpoint service."
  nullable    = false
  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 32 && can(regex("^[A-Za-z0-9-]+$", var.name))
    error_message = "name must be 1-32 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the Network Load Balancer will be created."
  nullable    = false
  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8,17}$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID in the format vpc-xxxxxxxx."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the Network Load Balancer. Must be in the same VPC and across multiple AZs for high availability. At least 1 subnet is required."
  nullable    = false
  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "subnet_ids must contain at least 1 subnet."
  }
  validation {
    condition     = alltrue([for s in var.subnet_ids : can(regex("^subnet-[a-f0-9]{8,17}$", s))])
    error_message = "All subnet_ids must be valid subnet IDs in the format subnet-xxxxxxxx."
  }
}

variable "target_ip" {
  type        = string
  description = "IP address of the target resource (e.g., RDS endpoint IP, Redshift private IP)."
  nullable    = false
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.target_ip))
    error_message = "target_ip must be a valid IPv4 address."
  }
}

variable "target_port" {
  type        = number
  description = "Port on the target resource."
  nullable    = false
  validation {
    condition     = var.target_port >= 1 && var.target_port <= 65535
    error_message = "target_port must be between 1 and 65535."
  }
}

variable "listener_port" {
  type        = number
  description = "NLB listener port. Defaults to target_port if not specified."
  default     = null
  validation {
    condition     = var.listener_port == null || (var.listener_port >= 1 && var.listener_port <= 65535)
    error_message = "listener_port must be between 1 and 65535."
  }
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Used to construct the AWS account principal ARN that is authorized to connect to the VPC endpoint service."
  nullable    = false
}

variable "databricks_gov_shard" {
  type        = string
  description = "Databricks GovCloud shard. null for commercial; \"civilian\" for AWS GovCloud civilian (FedRAMP High); \"dod\" for IL5/DoD."
  default     = null
  validation {
    condition     = var.databricks_gov_shard == null || contains(["civilian", "dod"], var.databricks_gov_shard)
    error_message = "databricks_gov_shard must be null, \"civilian\", or \"dod\"."
  }
}

variable "aws_partition" {
  type        = string
  description = "AWS partition for ARN construction. Use \"aws\" for commercial; \"aws-us-gov\" for GovCloud (both civilian and DoD shards)."
  nullable    = false
  validation {
    condition     = contains(["aws", "aws-us-gov"], var.aws_partition)
    error_message = "aws_partition must be \"aws\" or \"aws-us-gov\"."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all AWS resources (NLB, target group, security group, VPC endpoint service)."
  default     = {}
}
