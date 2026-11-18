locals {
  # Subnetwork name derived from the resource prefix.
  subnetwork_name = coalesce(var.subnetwork_name, "${var.resource_prefix}-subnet")

  # Secondary IP range names derived from the resource prefix.
  # These names are referenced in the databricks_mws_networks gcp_network_info block
  # and exposed as outputs for downstream modules.
  pod_secondary_range_name     = coalesce(var.pod_secondary_range_name, "${var.resource_prefix}-pods")
  service_secondary_range_name = coalesce(var.service_secondary_range_name, "${var.resource_prefix}-services")
  firewall_rule_name           = coalesce(var.firewall_rule_name, "db-${local.subnetwork_name}-ingress")

  # PSC endpoint wiring: only include the vpc_endpoints block when at least one list is non-empty.
  has_vpc_endpoints = (
    var.vpc_endpoint_ids != null &&
    (
      (var.vpc_endpoint_ids.dataplane_relay != null && length(var.vpc_endpoint_ids.dataplane_relay) > 0) ||
      (var.vpc_endpoint_ids.rest_api != null && length(var.vpc_endpoint_ids.rest_api) > 0)
    )
  )
}
