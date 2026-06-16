resource "databricks_external_location" "this" {
  provider = databricks.workspace

  for_each = var.locations

  name            = each.key
  url             = each.value.url
  credential_name = each.value.storage_credential_id
  comment         = each.value.comment
  read_only       = each.value.read_only
  skip_validation = each.value.skip_validation
}

resource "databricks_grants" "this" {
  provider = databricks.workspace

  for_each = {
    for name, loc in var.locations :
    name => loc.grants
    if length(loc.grants) > 0
  }

  external_location = databricks_external_location.this[each.key].name

  dynamic "grant" {
    for_each = each.value

    content {
      principal  = grant.key
      privileges = grant.value
    }
  }
}
