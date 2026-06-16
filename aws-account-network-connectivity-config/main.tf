resource "databricks_mws_network_connectivity_config" "this" {
  provider = databricks.account
  name     = var.name
  region   = var.region
}
