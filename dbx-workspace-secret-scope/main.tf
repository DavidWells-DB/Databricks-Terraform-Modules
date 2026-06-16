resource "databricks_secret_scope" "this" {
  provider = databricks.workspace

  for_each = var.scopes

  name                     = each.key
  initial_manage_principal = each.value.initial_manage_principal

  dynamic "keyvault_metadata" {
    for_each = each.value.keyvault_metadata != null ? [each.value.keyvault_metadata] : []

    content {
      resource_id = keyvault_metadata.value.resource_id
      dns_name    = keyvault_metadata.value.dns_name
    }
  }
}
