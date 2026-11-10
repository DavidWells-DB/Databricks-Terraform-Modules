locals {
  # base always; a "-privatelink" variant added when enable_privatelink — the PLAN-TIME-KNOWN
  # switch (distinct names prevent the CBD/self-collision on the metadata-only registration).
  network_configs = merge(
    { base = var.network_name },
    var.enable_privatelink ? { privatelink = "${var.network_name}-privatelink" } : {},
  )

  # Which registration the workspace should use: the PrivateLink one when endpoints are
  # in play, otherwise base.
  active_network = var.enable_privatelink ? "privatelink" : "base"
}
