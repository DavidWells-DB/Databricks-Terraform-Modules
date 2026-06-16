locals {
  # Derive a stable Access Connector name when the caller does not supply one.
  access_connector_name = coalesce(var.access_connector_name, "dbx-access-connector-${var.credential_name}")
}
