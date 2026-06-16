resource "databricks_catalog" "this" {
  for_each = var.catalogs

  provider = databricks.workspace

  metastore_id   = var.metastore_id
  name           = each.key
  comment        = each.value.comment
  storage_root   = each.value.storage_root
  isolation_mode = each.value.isolation_mode
  properties     = each.value.properties
}

# One databricks_grants block per catalog that has a non-empty grants list.
# databricks_grants is authoritative for the privilege set on the securable — it replaces
# any grants not listed here. Callers own the full grant state for catalogs managed by
# this module.
resource "databricks_grants" "this" {
  for_each = {
    for name, cfg in var.catalogs : name => cfg
    if length(cfg.grants) > 0
  }

  provider = databricks.workspace

  catalog = databricks_catalog.this[each.key].name

  dynamic "grant" {
    for_each = each.value.grants
    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}
