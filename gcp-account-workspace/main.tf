resource "databricks_mws_workspaces" "this" {
  provider       = databricks.account
  account_id     = var.databricks_account_id
  workspace_name = var.workspace_name
  # deployment_name is NOT requested on GCP — the platform assigns its own
  # (<workspace-id>.9 format), and requesting a custom one is silently ignored:
  # the create response records the requested value, the first refresh corrects
  # it, and every fresh state's first plan shows an output-only drift (E11-class
  # false positive — live 2026-10-20, matrix w5). The deployment_name OUTPUT is
  # the readback of the real platform value.
  location = var.region

  cloud_resource_container {
    gcp {
      project_id = var.project_id
    }
  }

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
}

# DNS propagation: workspace_url returned by databricks_mws_workspaces is not immediately
# resolvable. Downstream workspace providers must wait for DNS to propagate before connecting.
# 30s is the sanctioned minimum delay per the Databricks module rules Rule 3.1.
resource "time_sleep" "dns_propagation" {
  depends_on      = [databricks_mws_workspaces.this]
  create_duration = "30s"
}
