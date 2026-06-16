# Bind the NCC to the workspace. A workspace can be bound to exactly one NCC;
# re-binding silently overwrites the previous binding.
resource "databricks_mws_ncc_binding" "this" {
  provider                       = databricks.account
  network_connectivity_config_id = var.network_connectivity_config_id
  workspace_id                   = var.workspace_id
}

# Create one private endpoint rule per entry in var.private_endpoint_rules.
# Rule types and applicable fields differ by cloud:
#   AWS:   endpoint_service + resource_names (S3 buckets) or domain_names (FQDNs)
#   Azure: resource_id + group_id or domain_names
resource "databricks_mws_ncc_private_endpoint_rule" "this" {
  provider = databricks.account

  for_each = { for r in var.private_endpoint_rules : r.key => r }

  network_connectivity_config_id = var.network_connectivity_config_id
  resource_id                    = each.value.resource_id
  group_id                       = each.value.group_id
  endpoint_service               = each.value.endpoint_service
  resource_names                 = each.value.resource_names
  domain_names                   = each.value.domain_names
  enabled                        = each.value.enabled

  depends_on = [databricks_mws_ncc_binding.this]
}

# Assign a network policy to the workspace for serverless compute access control.
# Created only when network_policy_id is provided (non-null).
resource "databricks_workspace_network_option" "this" {
  provider = databricks.workspace
  count    = var.network_policy_id != null ? 1 : 0

  workspace_id      = var.workspace_id
  network_policy_id = var.network_policy_id
}
