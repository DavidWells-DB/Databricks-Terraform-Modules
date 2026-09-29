locals {
  # Databricks account host URL, derived from gov_shard, for documentation and output use.
  # The actual provider configuration (host =) lives in the root composition;
  # this local is exposed as an output to help callers validate their provider config.
  # Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud
  databricks_account_host = (
    var.databricks_gov_shard == "civilian" ? "https://accounts.cloud.databricks.us" :
    var.databricks_gov_shard == "dod" ? "https://accounts-dod.cloud.databricks.mil" :
    "https://accounts.cloud.databricks.com"
  )

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
    "${var.resource_prefix}-pl-${idx}" => {
      cidr = cidr
      az   = var.azs[idx % length(var.azs)]
    }
  }

  # Network config registrations, keyed by role. databricks_mws_networks is REPLACE-ONLY for
  # vpc_endpoints (immutable per Databricks docs; the provider Update fn is a no-op). Adding
  # back-end PrivateLink to a RUNNING workspace is therefore Databricks' documented two-step
  # procedure ("Update a running workspace"): register a NEW network config, then repoint the
  # workspace to it. Databricks does NOT require deleting the old config, imposes no documented
  # limit on network configs, and an unattached config is metadata-only and free.
  #
  # So we RETAIN the pre-PrivateLink "base" config instead of force-replacing (deleting) it:
  # "base" is always present; enabling PrivateLink ADDS a "privatelink" key and the caller
  # repoints the workspace to it in place. Nothing is deleted while attached, so the
  # "cannot delete a network while it is attached to a workspace" failure cannot occur. After a
  # cutover the detached "base" config lingers (≤1 per workspace) — harmless; delete it
  # deliberately later if desired (safe once no workspace references it). map(string) keeps the
  # for_each type homogeneous (key => network_name); the endpoints block is gated on the key.
  # KEY SET is driven by var.enable_privatelink (a plan-time-known bool), NOT by
  # var.vpc_endpoint_ids — those IDs are usually known only after apply (they come from
  # endpoints created in the same run), and for_each keys must be known at plan time.
  network_configs = merge(
    { base = var.network_name },
    var.enable_privatelink ? { privatelink = "${var.network_name}-privatelink" } : {}
  )

  # The config the workspace must point at: the PrivateLink one when enabled, else base.
  active_network = var.enable_privatelink ? "privatelink" : "base"
}
