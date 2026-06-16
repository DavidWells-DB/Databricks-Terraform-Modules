locals {
  # Derive consistent child resource names from the firewall name to keep the deployment
  # self-describing and avoid callers needing to manage five separate naming inputs.
  firewall_policy_name     = "${var.firewall_name}-policy"
  ip_group_name            = "${var.firewall_name}-spoke-ips"
  public_ip_name           = "${var.firewall_name}-pip"
  route_table_name         = "${var.firewall_name}-spoke-rt"
  rule_collection_name     = "${var.firewall_name}-databricks-rules"
  forced_tunnel_route_name = "route-to-firewall"
}
