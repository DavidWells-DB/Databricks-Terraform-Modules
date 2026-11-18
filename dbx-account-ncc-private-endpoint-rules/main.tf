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
}
