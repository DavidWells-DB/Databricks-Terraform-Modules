locals {
  # Build per-subnet maps keyed by index for for_each stability.
  private_subnets = {
    for idx, cidr in var.private_subnet_cidrs :
    "${var.resource_prefix}-private-${idx}" => {
      cidr = cidr
      az   = var.azs[idx % length(var.azs)]
    }
  }

  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs :
    "${var.resource_prefix}-public-${idx}" => {
      cidr = cidr
      az   = var.azs[idx % length(var.azs)]
    }
  }

  privatelink_subnets = {
    for idx, cidr in var.privatelink_subnet_cidrs :
    "${var.resource_prefix}-privatelink-${idx}" => {
      cidr = cidr
      az   = var.azs[idx % length(var.azs)]
    }
  }
}
