variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which to create the Internet Gateway and NAT Gateway."
  nullable    = false
  validation {
    condition     = can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    error_message = "vpc_id must be a valid AWS VPC ID (e.g. vpc-0a1b2c3d4e5f67890)."
  }
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs into which the NAT Gateways are placed. At least one subnet is required. Each NAT Gateway is placed in the corresponding subnet by index (wrapping with modulo if fewer subnets than NAT Gateways)."
  nullable    = false
  validation {
    condition     = length(var.public_subnet_ids) >= 1
    error_message = "At least one public subnet ID is required."
  }
  validation {
    condition     = alltrue([for id in var.public_subnet_ids : can(regex("^subnet-[a-f0-9]+$", id))])
    error_message = "Each entry in public_subnet_ids must be a valid AWS subnet ID (e.g. subnet-0a1b2c3d4e5f67890)."
  }
}

variable "private_route_table_ids" {
  type        = list(string)
  description = "List of private route table IDs to which the 0.0.0.0/0 → NAT Gateway route is added. At least one route table ID is required."
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

variable "nat_gateway_count" {
  type        = number
  description = "Number of NAT Gateways to create. Default 1 is sufficient for non-HA deployments. Set to match the number of public subnets for full AZ-redundant HA."
  default     = 1
  nullable    = false
  validation {
    condition     = var.nat_gateway_count >= 1
    error_message = "nat_gateway_count must be at least 1."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all AWS resources created by this module (Internet Gateway, Elastic IPs, NAT Gateways, and routes)."
  default     = {}
}
