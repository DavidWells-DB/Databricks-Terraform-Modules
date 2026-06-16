resource "databricks_mws_workspaces" "this" {
  provider       = databricks.account
  account_id     = var.databricks_account_id
  workspace_name = var.workspace_name
  location       = var.region

  cloud_resource_container {
    gcp {
      project_id = var.project_id
    }
  }

  # Serverless-only mode: no VPC, no GKE node pool, no classic compute plane.
  # Network, storage, and GKE configurations are omitted entirely — they are not
  # required (and not valid) when compute_mode = "SERVERLESS".
  compute_mode = "SERVERLESS"

  deployment_name = "${var.resource_prefix}-serverless"

  managed_services_customer_managed_key_id = var.managed_services_key_id

  custom_tags = var.custom_tags

  lifecycle {
    # custom_tags may be modified outside Terraform via the Databricks UI or account console.
    # Ignoring drifted tags prevents unexpected plan noise for operators managing tags manually.
    ignore_changes = [custom_tags]
  }
}

# DNS propagation: workspace_url returned by databricks_mws_workspaces is not immediately
# resolvable. Downstream workspace providers must wait for DNS to propagate before connecting.
# 30s is the sanctioned minimum delay per DATABRICKS_RULES.md Rule 3.1.
resource "time_sleep" "dns_propagation" {
  depends_on      = [databricks_mws_workspaces.this]
  create_duration = "30s"
}
