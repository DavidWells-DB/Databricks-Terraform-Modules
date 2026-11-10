# Bind a UC securable (catalog, or any securable_type the provider supports) to one or
# many workspaces — the finisher for ISOLATED catalogs: dbx-uc-catalog sets
# isolation_mode = "ISOLATED" (which un-shares the catalog from every metastore-attached
# workspace); THIS module then binds exactly the workspaces that should reach it.
#
# Design after the config-driven prior art (alexott/terraform-playground, reviewed
# 2026-11-10): a per-(securable, workspace) keyed map (the for_each-over-tuples trap is
# designed out — keys are caller-chosen plan-time constants); read-only vs read-write via
# binding_type; the NEW databricks_workspace_binding resource (databricks_catalog_workspace_binding
# is the deprecated twin at this provider version). Applies from EITHER provider surface
# (account or workspace); the governance root maps the provider it holds.
resource "databricks_workspace_binding" "this" {
  provider = databricks.workspace

  for_each = var.bindings

  workspace_id   = each.value.workspace_id
  securable_type = each.value.securable_type
  securable_name = each.value.securable_name
  binding_type   = each.value.binding_type
}
