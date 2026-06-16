variable "resource_prefix" {
  type        = string
  description = "Prefix applied to all resource names created by this module (Transit Gateway, route tables). Use a short, consistent identifier such as your team or environment name."
  nullable    = false
  validation {
    # 1-24 chars; alphanumeric and hyphens only. Long prefixes produce names that exceed the
    # AWS 255-char Name tag limit when combined with suffixes added inside the module.
    condition     = length(var.resource_prefix) >= 1 && length(var.resource_prefix) <= 24 && can(regex("^[A-Za-z0-9-]+$", var.resource_prefix))
    error_message = "resource_prefix must be 1-24 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "tgw_asn" {
  type        = number
  description = "Private Autonomous System Number (ASN) for the Transit Gateway's BGP sessions. Must be in the private ASN range: 64512-65534 (16-bit) or 4200000000-4294967294 (32-bit)."
  nullable    = false
  validation {
    # AWS-documented private ASN ranges for TGW:
    # https://docs.aws.amazon.com/vpc/latest/tgw/tgw-transit-gateways.html
    condition = (
      (var.tgw_asn >= 64512 && var.tgw_asn <= 65534) ||
      (var.tgw_asn >= 4200000000 && var.tgw_asn <= 4294967294)
    )
    error_message = "tgw_asn must be in the private ASN range 64512-65534 (16-bit) or 4200000000-4294967294 (32-bit)."
  }
}

variable "vpc_attachments" {
  type = map(object({
    vpc_id     = string
    subnet_ids = list(string)
  }))
  description = "Map of attachment name to VPC attachment configuration. Each entry creates one Transit Gateway VPC attachment. The key becomes the attachment's Name tag. subnet_ids must each be in a different Availability Zone within the VPC."
  nullable    = false
  validation {
    # Each attachment must supply at least one subnet.
    condition     = alltrue([for k, v in var.vpc_attachments : length(v.subnet_ids) >= 1])
    error_message = "Each vpc_attachment entry must include at least one subnet_id."
  }
}

variable "dns_support" {
  type        = string
  description = "Whether DNS resolution support is enabled on the Transit Gateway. Must be \"enable\" or \"disable\"."
  default     = "enable"
  validation {
    condition     = contains(["enable", "disable"], var.dns_support)
    error_message = "dns_support must be \"enable\" or \"disable\"."
  }
}

variable "vpn_ecmp_support" {
  type        = string
  description = "Whether Equal Cost Multi-path (ECMP) routing over VPN tunnels is enabled. Must be \"enable\" or \"disable\"."
  default     = "enable"
  validation {
    condition     = contains(["enable", "disable"], var.vpn_ecmp_support)
    error_message = "vpn_ecmp_support must be \"enable\" or \"disable\"."
  }
}

variable "default_route_table_association" {
  type        = string
  description = "Whether attachments are automatically associated with the Transit Gateway's default route table. Must be \"enable\" or \"disable\". Disable when managing route table associations explicitly (recommended for Databricks hub-and-spoke topologies)."
  default     = "disable"
  validation {
    condition     = contains(["enable", "disable"], var.default_route_table_association)
    error_message = "default_route_table_association must be \"enable\" or \"disable\"."
  }
}

variable "default_route_table_propagation" {
  type        = string
  description = "Whether attachments automatically propagate routes to the Transit Gateway's default route table. Must be \"enable\" or \"disable\". Disable when managing route propagations explicitly (recommended for Databricks hub-and-spoke topologies)."
  default     = "disable"
  validation {
    condition     = contains(["enable", "disable"], var.default_route_table_propagation)
    error_message = "default_route_table_propagation must be \"enable\" or \"disable\"."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources created by this module."
  default     = {}
}
