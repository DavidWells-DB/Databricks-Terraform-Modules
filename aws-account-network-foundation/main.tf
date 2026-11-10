# ADR-0007 account-foundation surface (AWS): the account-scoped, N:1 network objects in ONE
# call — the Network Connectivity Config (NCC) and the account network policy — composed from
# their single-owner modules. Workspaces then BIND to these by ID
# (dbx-workspace-network-serverless for the NCC, dbx-workspace-network-policy-binding for the
# policy); nothing here is workspace-specific. Per ADR-0007 the foundation is created once per
# account/region and shared; the binding stays a workspace-root concern.
#
# Single-owner chain (H5-1, 2026-11-10): NCC object = aws-account-network-connectivity-config;
# policy object = dbx-account-network-policy. This module composes BOTH and owns neither.

module "ncc" {
  source = "../aws-account-network-connectivity-config"

  providers = { databricks.account = databricks.account }

  name   = var.ncc_name
  region = var.region
}

module "policy" {
  count  = var.create_policy ? 1 : 0
  source = "../dbx-account-network-policy"

  providers = { databricks.account = databricks.account }

  databricks_account_id        = var.databricks_account_id
  policy_name                 = var.policy_name
  egress_mode                 = var.egress_mode
  enforcement_mode            = var.enforcement_mode
  allowed_internet_destinations = var.allowed_internet_destinations
  allowed_storage_destinations  = var.allowed_storage_destinations
}
