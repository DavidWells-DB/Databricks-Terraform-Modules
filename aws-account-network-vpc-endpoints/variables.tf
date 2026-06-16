variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which to create the VPC endpoints."
  nullable    = false
  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "vpc_id must be a valid AWS VPC ID matching the pattern vpc-<hex>."
  }
}

variable "region" {
  type        = string
  description = "AWS region for endpoint service names (e.g., \"us-east-1\"). Must match the region of the VPC and subnets."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.region))
    error_message = "region must be a valid AWS region name (e.g., us-east-1, eu-west-2, ap-southeast-1)."
  }
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for the STS and Kinesis interface endpoints. Databricks compute nodes reside in these subnets."
  nullable    = false
  validation {
    condition     = length(var.private_subnet_ids) >= 1 && alltrue([for id in var.private_subnet_ids : can(regex("^subnet-[0-9a-f]+$", id))])
    error_message = "private_subnet_ids must be a non-empty list of valid subnet IDs matching the pattern subnet-<hex>."
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs to associate with the STS and Kinesis interface endpoints. Must allow HTTPS (443) from Databricks compute nodes."
  nullable    = false
  validation {
    condition     = length(var.security_group_ids) >= 1 && alltrue([for id in var.security_group_ids : can(regex("^sg-[0-9a-f]+$", id))])
    error_message = "security_group_ids must be a non-empty list of valid security group IDs matching the pattern sg-<hex>."
  }
}

variable "private_route_table_ids" {
  type        = list(string)
  description = "Route table IDs to associate with the S3 gateway endpoint. Typically one per private subnet / availability zone."
  nullable    = false
  validation {
    condition     = length(var.private_route_table_ids) >= 1 && alltrue([for id in var.private_route_table_ids : can(regex("^rtb-[0-9a-f]+$", id))])
    error_message = "private_route_table_ids must be a non-empty list of valid route table IDs matching the pattern rtb-<hex>."
  }
}

variable "databricks_gov_shard" {
  type        = string
  description = "Databricks GovCloud shard. null for commercial; \"civilian\" for AWS GovCloud civilian (FedRAMP High); \"dod\" for IL5/DoD. Drives the AWS partition used in endpoint policy ARNs."
  default     = null
  validation {
    condition     = var.databricks_gov_shard == null || contains(["civilian", "dod"], var.databricks_gov_shard)
    error_message = "databricks_gov_shard must be null, \"civilian\", or \"dod\"."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all VPC endpoints created by this module."
  default     = {}
}
