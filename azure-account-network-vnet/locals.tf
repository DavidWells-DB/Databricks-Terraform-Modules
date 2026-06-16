locals {
  # Whether to create the optional private endpoint subnet.
  create_pe_subnet = var.pe_subnet_name != null && var.pe_subnet_cidr != null
}
