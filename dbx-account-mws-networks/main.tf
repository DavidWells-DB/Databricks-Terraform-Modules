# Register a customer VPC (or any existing subnets + security group) with the Databricks
# account API — the BYO-VPC entry point of the three-piece split (2026-11-10): pair with
# aws-account-vpc (the cloud half) or bring your own VPC entirely and pass its IDs here.
#
# Keyed by role: always a "base" config; a separate "privatelink" config is ADDED when
# enable_privatelink is true. Adding PrivateLink to a running workspace therefore creates
# the new "privatelink" registration and RETAINS "base" (the caller repoints the workspace's
# network_id in place). No create_before_destroy and no replacement: nothing is deleted
# while attached, so the delete-while-attached failure cannot occur ("Network is being used
# by active workspace", live 2026-08-03 — the bug class the 2026-08-03 fixes address; the
# PL-variant naming prevents the CBD/self-collision failure). Both configs may reference
# the same subnets — Databricks explicitly allows multiple network config objects on the
# same VPC/subnets (docs: customer-managed VPC, "share one subnet across multiple workspaces").
resource "databricks_mws_networks" "this" {
  for_each = local.network_configs

  provider           = databricks.account
  account_id         = var.databricks_account_id
  network_name       = each.value
  security_group_ids = var.security_group_ids
  subnet_ids         = var.private_subnet_ids
  vpc_id             = var.vpc_id

  dynamic "vpc_endpoints" {
    # PrivateLink endpoint IDs belong only to the "privatelink" registration (and only when
    # supplied; enable_privatelink may be set a plan before the endpoint IDs are known — it,
    # not vpc_endpoint_ids, drives the resource key set, so known-after-apply endpoint IDs are
    # safe here).
    for_each = each.key == "privatelink" && var.vpc_endpoint_ids != null ? [var.vpc_endpoint_ids] : []

    content {
      dataplane_relay = vpc_endpoints.value.relay_id != null ? [vpc_endpoints.value.relay_id] : []
      rest_api        = vpc_endpoints.value.rest_api_id != null ? [vpc_endpoints.value.rest_api_id] : []
    }
  }
}

# NOTE: no moved blocks here BY DESIGN. The child is new (2026-11-10) — no consumer holds
# state at this module's addresses. Historical migration (pre-v0.3.0 unkeyed, v0.3.x keyed)
# is owned entirely by the composed aws-account-network-vpc module's moved chain, which
# retargets state into this module's keys; a moved block here would collide with it
# ("ambiguous move statements", caught in tests).
