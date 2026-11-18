# One-call composition of the three-piece split (2026-11-10):
#   aws-account-vpc          — the pure cloud side (VPC, subnets, route tables, SG)
#   dbx-account-mws-networks — the pure Databricks-side registration (the BYO-VPC entry point)
# BYO-VPC callers consume those two directly; this module keeps the original single-call
# surface (identical variables and outputs) for existing consumers, with moved blocks so
# upgrades show moves, not destroy/create.
#
# Registration semantics carried over verbatim (live-verified 2026-08-03): adding back-end
# PrivateLink creates the "privatelink" registration and RETAINS "base" — the caller repoints
# the workspace's network_id in place; nothing is deleted while attached.

module "vpc" {
  source = "../aws-account-vpc"

  resource_prefix                = var.resource_prefix
  vpc_name                       = var.vpc_name
  security_group_name            = var.security_group_name
  private_subnet_name_prefix     = var.private_subnet_name_prefix
  public_subnet_name_prefix      = var.public_subnet_name_prefix
  privatelink_subnet_name_prefix = var.privatelink_subnet_name_prefix
  vpc_cidr                       = var.vpc_cidr
  private_subnet_cidrs           = var.private_subnet_cidrs
  public_subnet_cidrs            = var.public_subnet_cidrs
  privatelink_subnet_cidrs       = var.privatelink_subnet_cidrs
  azs                            = var.azs
  tags                           = var.tags
}

module "registration" {
  source = "../dbx-account-mws-networks"

  providers = { databricks.account = databricks.account }

  databricks_account_id = var.databricks_account_id
  network_name          = var.network_name
  enable_privatelink    = var.enable_privatelink
  vpc_endpoint_ids      = var.vpc_endpoint_ids
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = [for _, id in module.vpc.private_subnet_ids : id]
  security_group_ids    = [module.vpc.security_group_id]
}

# --- upgrade paths: same objects, new addresses (Rule 10.3 — moves, not destroy/create).
# Chained within this module's space first (unkeyed→keyed is the original v0.3.0 move,
# retained), then keyed→child — a move chain, so every historical consumer state reaches
# the child without destroy/create, with no two statements sharing a destination.
moved {
  from = databricks_mws_networks.this
  to   = databricks_mws_networks.this["base"]
}
moved {
  from = databricks_mws_networks.this["base"]
  to   = module.registration.databricks_mws_networks.this["base"]
}
moved {
  from = databricks_mws_networks.this["privatelink"]
  to   = module.registration.databricks_mws_networks.this["privatelink"]
}
