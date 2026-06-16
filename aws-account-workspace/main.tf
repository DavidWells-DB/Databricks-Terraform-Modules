resource "databricks_mws_workspaces" "this" {
  provider       = databricks.account
  account_id     = var.databricks_account_id
  workspace_name = var.workspace_name
  aws_region     = var.region

  credentials_id           = var.credentials_id
  storage_configuration_id = var.storage_configuration_id
  network_id               = var.databricks_network_id

  private_access_settings_id = var.private_access_settings_id

  managed_services_customer_managed_key_id = var.managed_services_key_id
  storage_customer_managed_key_id          = var.workspace_storage_key_id

  custom_tags = var.custom_tags

  lifecycle {
    # custom_tags may be modified outside Terraform via the Databricks UI or account console.
    # Ignoring drifted tags prevents unexpected plan noise for operators managing tags manually.
    ignore_changes = [custom_tags]
  }

  token {}
}

# DNS propagation: workspace_url returned by databricks_mws_workspaces is not immediately
# resolvable. Downstream workspace providers must wait for DNS to propagate before connecting.
# 30s is the sanctioned minimum delay per DATABRICKS_RULES.md Rule 3.1.
resource "time_sleep" "dns_propagation" {
  depends_on      = [databricks_mws_workspaces.this]
  create_duration = "30s"
}

# NCC binding is optional and only created when network_connectivity_config_id is provided.
resource "databricks_mws_ncc_binding" "this" {
  count = var.network_connectivity_config_id != null ? 1 : 0

  provider                       = databricks.account
  network_connectivity_config_id = var.network_connectivity_config_id
  workspace_id                   = databricks_mws_workspaces.this.workspace_id
}
