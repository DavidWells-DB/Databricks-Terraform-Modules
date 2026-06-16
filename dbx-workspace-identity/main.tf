# Workspace permission API readiness: the permission assignment API can return 404
# for ~20s after a workspace becomes reachable. time_sleep is the sanctioned
# workaround per DATABRICKS_RULES.md Rule 3.1.
resource "time_sleep" "workspace_api_ready" {
  create_duration = "20s"
}

resource "databricks_mws_permission_assignment" "this" {
  provider = databricks.account

  for_each = var.assignments

  workspace_id = var.workspace_id
  principal_id = each.value.principal_id
  permissions  = each.value.roles

  depends_on = [time_sleep.workspace_api_ready]

  lifecycle {
    # principal_id values can shift when SCIM/AIM resolves IdP-sourced identities.
    # Ignoring prevents spurious plan diffs after IdP syncs. See DATABRICKS_RULES.md Rule 3.2.
    ignore_changes = [principal_id]
  }
}
