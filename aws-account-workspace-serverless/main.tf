resource "databricks_mws_workspaces" "this" {
  provider   = databricks.account
  account_id = var.databricks_account_id

  workspace_name = var.workspace_name
  aws_region     = var.region
  compute_mode   = "SERVERLESS"

  # Serverless workspaces do not use credentials_id or storage_configuration_id.
  # Those fields are prohibited when compute_mode = "SERVERLESS".

  # NOTE: managed-services CMK is NOT applied here — the field is not valid in
  # the serverless CREATE body (live 2026-10-19: 'Cannot parse request body').
  # The documented mechanism is POST-CREATION: register the KMS key as an
  # account-level key configuration with use_cases = ["MANAGED_SERVICES"]
  # (the workspace takes the DATABRICKS KEY-CONFIGURATION ID, not the raw ARN),
  # then PATCH the workspace's managed_services_customer_managed_key_id and
  # poll for RUNNING. Enterprise tier required. See the README's CMK section.
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
