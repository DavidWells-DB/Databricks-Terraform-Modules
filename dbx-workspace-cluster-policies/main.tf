resource "databricks_cluster_policy" "this" {
  provider = databricks.workspace
  for_each = var.policies

  name                               = each.key
  description                        = each.value.description
  definition                         = each.value.definition
  policy_family_id                   = each.value.policy_family_id
  policy_family_definition_overrides = each.value.policy_family_definition_overrides
  max_clusters_per_user              = each.value.max_clusters_per_user
}

resource "databricks_permissions" "this" {
  provider = databricks.workspace
  # Only create permissions resources for policies that have assignments defined.
  for_each = { for k, v in var.policy_assignments : k => v if length(v.access_controls) > 0 }

  cluster_policy_id = databricks_cluster_policy.this[each.key].id

  dynamic "access_control" {
    for_each = each.value.access_controls
    content {
      group_name             = access_control.value.group_name
      user_name              = access_control.value.user_name
      service_principal_name = access_control.value.service_principal_name
      permission_level       = "CAN_USE"
    }
  }
}
