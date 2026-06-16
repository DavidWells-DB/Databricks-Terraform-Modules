variable "requester_vpc_id" {
  type        = string
  description = "ID of the requester (initiating) VPC. This is typically the Databricks data-plane VPC."
  nullable    = false
  validation {
    # AWS VPC IDs match vpc-<hex> per https://docs.aws.amazon.com/vpc/latest/userguide/vpc-peering-overview.html
    condition     = can(regex("^vpc-[0-9a-f]+$", var.requester_vpc_id))
    error_message = "requester_vpc_id must be a valid AWS VPC ID in the form vpc-<hex> (e.g., vpc-0a1b2c3d4e5f6a7b8)."
  }
}

variable "accepter_vpc_id" {
  type        = string
  description = "ID of the accepter (destination) VPC. This is typically the hub/shared-services VPC."
  nullable    = false
  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.accepter_vpc_id))
    error_message = "accepter_vpc_id must be a valid AWS VPC ID in the form vpc-<hex> (e.g., vpc-0a1b2c3d4e5f6a7b8)."
  }
}

variable "requester_route_table_ids" {
  type        = list(string)
  description = "Route table IDs in the requester VPC that should receive a route to the accepter VPC's CIDR block. Typically includes all private route tables in the data-plane VPC."
  nullable    = false
  validation {
    condition     = length(var.requester_route_table_ids) >= 1 && alltrue([for rt in var.requester_route_table_ids : can(regex("^rtb-[0-9a-f]+$", rt))])
    error_message = "requester_route_table_ids must be a non-empty list of valid route table IDs in the form rtb-<hex>."
  }
}

variable "accepter_route_table_ids" {
  type        = list(string)
  description = "Route table IDs in the accepter VPC that should receive a route back to the requester VPC's CIDR block. Typically includes all private route tables in the hub/shared-services VPC."
  nullable    = false
  validation {
    condition     = length(var.accepter_route_table_ids) >= 1 && alltrue([for rt in var.accepter_route_table_ids : can(regex("^rtb-[0-9a-f]+$", rt))])
    error_message = "accepter_route_table_ids must be a non-empty list of valid route table IDs in the form rtb-<hex>."
  }
}

variable "requester_vpc_cidr" {
  type        = string
  description = "CIDR block of the requester VPC. Used to add a route in accepter route tables pointing back to this VPC."
  nullable    = false
  validation {
    # IPv4 CIDR block format: x.x.x.x/n
    condition     = can(cidrnetmask(var.requester_vpc_cidr))
    error_message = "requester_vpc_cidr must be a valid IPv4 CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "accepter_vpc_cidr" {
  type        = string
  description = "CIDR block of the accepter VPC. Used to add a route in requester route tables pointing to the accepter VPC."
  nullable    = false
  validation {
    condition     = can(cidrnetmask(var.accepter_vpc_cidr))
    error_message = "accepter_vpc_cidr must be a valid IPv4 CIDR block (e.g., 10.1.0.0/16)."
  }
}

variable "accepter_account_id" {
  type        = string
  description = "AWS account ID that owns the accepter VPC. Set to the same value as the requester's account ID for same-account peering, or a different account ID for cross-account peering."
  nullable    = false
  validation {
    # AWS account IDs are exactly 12 digits
    condition     = can(regex("^[0-9]{12}$", var.accepter_account_id))
    error_message = "accepter_account_id must be a 12-digit AWS account ID."
  }
}

variable "accepter_region" {
  type        = string
  description = "AWS region of the accepter VPC. For same-region peering, set this to the same region as the requester. For cross-region peering, set to the accepter's region."
  nullable    = false
  validation {
    # AWS region format: <area>-<direction>-<number>  (e.g., us-east-1, eu-west-2, ap-southeast-1)
    condition     = can(regex("^[a-z]{2,}-[a-z]+-[0-9]+$", var.accepter_region))
    error_message = "accepter_region must be a valid AWS region identifier (e.g., us-east-1, eu-west-2)."
  }
}

variable "peering_name" {
  type        = string
  description = "Name tag applied to the VPC peering connection and its accepter. Should be descriptive and unique within the AWS account."
  nullable    = false
  validation {
    condition     = length(var.peering_name) >= 1 && length(var.peering_name) <= 255
    error_message = "peering_name must be between 1 and 255 characters."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all taggable AWS resources created by this module."
  default     = {}
}
