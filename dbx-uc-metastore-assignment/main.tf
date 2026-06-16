resource "databricks_metastore_assignment" "this" {
  provider = databricks.account

  for_each = var.workspace_ids

  metastore_id = var.metastore_id
  workspace_id = each.value
}

# Sets the default catalog for the workspace configured in databricks.workspace.
# databricks_default_namespace_setting is workspace-scoped and requires a workspace-level
# provider — it cannot be iterated across multiple workspaces in a single module invocation.
# Set default_catalog_name = null to skip this resource.
resource "databricks_default_namespace_setting" "this" {
  provider = databricks.workspace
  count    = var.default_catalog_name != null ? 1 : 0

  namespace {
    value = var.default_catalog_name
  }

  depends_on = [databricks_metastore_assignment.this]
}
