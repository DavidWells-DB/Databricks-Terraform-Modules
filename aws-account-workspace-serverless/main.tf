resource "databricks_mws_workspaces" "this" {
  provider   = databricks.account
  account_id = var.databricks_account_id

  workspace_name = var.workspace_name
  aws_region     = var.region
  compute_mode   = "SERVERLESS"

  # Serverless workspaces do not use credentials_id or storage_configuration_id.
  # Those fields are prohibited when compute_mode = "SERVERLESS".

  # NOTE: NO managed_services_customer_managed_key_id — LIVE 2026-10-19 (readiness
  # campaign, rc-aw1 probe): the account API rejects the combination outright
  # ("Cannot parse request body") when compute_mode = SERVERLESS — identical to GCP.
  # CMK is not supported on AWS serverless workspaces at the API level.
  deployment_name = var.deployment_name
  custom_tags     = var.custom_tags

  lifecycle {
    # custom_tags may be modified by humans via the Databricks UI or API outside Terraform.
    # Ignore drift to avoid unintended overwrites. See the Databricks module rules Rule 3.2.
    ignore_changes = [custom_tags]
  }
}

resource "databricks_mws_ncc_binding" "this" {
  provider = databricks.account

  # Only created when a network_connectivity_config_id is supplied.
  count = var.network_connectivity_config_id != null ? 1 : 0

  network_connectivity_config_id = var.network_connectivity_config_id
  workspace_id                   = databricks_mws_workspaces.this.workspace_id
}
