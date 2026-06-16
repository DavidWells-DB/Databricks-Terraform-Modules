variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which the Network Firewall is deployed."
  nullable    = false
  validation {
    condition     = can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    error_message = "vpc_id must be a valid AWS VPC ID (e.g. vpc-0a1b2c3d4e5f67890)."
  }
}

variable "firewall_name" {
  type        = string
  description = "Name for the AWS Network Firewall and its associated policy. Must be 1-128 characters, alphanumeric and hyphens only."
  nullable    = false
  validation {
    # AWS Network Firewall name: 1-128 chars, alphanumeric and hyphens per
    # https://docs.aws.amazon.com/network-firewall/latest/APIReference/API_CreateFirewall.html
    condition     = length(var.firewall_name) >= 1 && length(var.firewall_name) <= 128 && can(regex("^[A-Za-z0-9-]+$", var.firewall_name))
    error_message = "firewall_name must be 1-128 characters containing only alphanumeric characters and hyphens."
  }
}

variable "firewall_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs in which the Network Firewall endpoints are deployed. One firewall endpoint is created per subnet. Subnets must be in distinct AZs for HA. At least one subnet is required."
  nullable    = false
  validation {
    condition     = length(var.firewall_subnet_ids) >= 1
    error_message = "At least one firewall subnet ID is required."
  }
  validation {
    condition     = alltrue([for id in var.firewall_subnet_ids : can(regex("^subnet-[a-f0-9]+$", id))])
    error_message = "Each entry in firewall_subnet_ids must be a valid AWS subnet ID (e.g. subnet-0a1b2c3d4e5f67890)."
  }
}

variable "private_route_table_ids" {
  type        = list(string)
  description = "List of private route table IDs to which the 0.0.0.0/0 route pointing to the firewall endpoint is added. Each route table receives a route to the firewall endpoint in the same AZ (by index). At least one route table ID is required."
  nullable    = false
  validation {
    condition     = length(var.private_route_table_ids) >= 1
    error_message = "At least one private route table ID is required."
  }
  validation {
    condition     = alltrue([for id in var.private_route_table_ids : can(regex("^rtb-[a-f0-9]+$", id))])
    error_message = "Each entry in private_route_table_ids must be a valid AWS route table ID (e.g. rtb-0a1b2c3d4e5f67890)."
  }
}

variable "stateful_rule_group_arns" {
  type        = list(string)
  description = "List of ARNs of stateful rule groups to associate with the firewall policy. May be empty if all filtering is handled by stateless rule groups."
  default     = []
  nullable    = false
  validation {
    condition     = alltrue([for arn in var.stateful_rule_group_arns : can(regex("^arn:[a-z0-9-]+:network-firewall:", arn))])
    error_message = "Each entry in stateful_rule_group_arns must be a valid AWS Network Firewall rule group ARN."
  }
}

variable "stateless_rule_group_arns" {
  type        = list(string)
  description = "List of ARNs of stateless rule groups to associate with the firewall policy. May be empty."
  default     = []
  nullable    = false
  validation {
    condition     = alltrue([for arn in var.stateless_rule_group_arns : can(regex("^arn:[a-z0-9-]+:network-firewall:", arn))])
    error_message = "Each entry in stateless_rule_group_arns must be a valid AWS Network Firewall rule group ARN."
  }
}

variable "stateless_default_actions" {
  type        = list(string)
  description = "Default actions for stateless packets not matching any stateless rule. Valid values: \"aws:pass\", \"aws:drop\", \"aws:forward_to_sfe\". At least one action is required."
  default     = ["aws:forward_to_sfe"]
  nullable    = false
  validation {
    condition     = length(var.stateless_default_actions) >= 1 && alltrue([for a in var.stateless_default_actions : contains(["aws:pass", "aws:drop", "aws:forward_to_sfe"], a)])
    error_message = "stateless_default_actions must be a non-empty list containing only \"aws:pass\", \"aws:drop\", or \"aws:forward_to_sfe\"."
  }
}

variable "stateless_fragment_default_actions" {
  type        = list(string)
  description = "Default actions for fragmented stateless packets not matching any stateless rule. Valid values: \"aws:pass\", \"aws:drop\", \"aws:forward_to_sfe\". At least one action is required."
  default     = ["aws:forward_to_sfe"]
  nullable    = false
  validation {
    condition     = length(var.stateless_fragment_default_actions) >= 1 && alltrue([for a in var.stateless_fragment_default_actions : contains(["aws:pass", "aws:drop", "aws:forward_to_sfe"], a)])
    error_message = "stateless_fragment_default_actions must be a non-empty list containing only \"aws:pass\", \"aws:drop\", or \"aws:forward_to_sfe\"."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all AWS resources created by this module (firewall, firewall policy, and routes)."
  default     = {}
}
