resource "databricks_schema" "this" {
  for_each = var.schemas

  provider = databricks.workspace

  catalog_name = var.catalog_name
  name         = each.key
  comment      = each.value.comment
  storage_root = each.value.storage_root
  properties   = each.value.properties
}

# One databricks_grants block per schema that has a non-empty grants list.
# databricks_grants is authoritative for the privilege set on the securable — it replaces
# any grants not listed here. Callers own the full grant state for schemas managed by
# this module.
resource "databricks_grants" "this" {
  for_each = {
    for name, cfg in var.schemas : name => cfg
    if length(cfg.grants) > 0
  }

  provider = databricks.workspace

  schema = "${var.catalog_name}.${databricks_schema.this[each.key].name}"

  dynamic "grant" {
    for_each = each.value.grants
    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}
