resource "databricks_mws_workspaces" "this" {
  provider   = databricks.account
  account_id = var.databricks_account_id

  workspace_name = var.workspace_name
  aws_region     = var.region
  compute_mode   = "SERVERLESS"

  # Serverless workspaces do not use credentials_id or storage_configuration_id.
  # Those fields are prohibited when compute_mode = "SERVERLESS".

  # managed-services CMK is valid only as a POST-CREATE update (live 2026-10-26).
  # Keep this null on the first apply. The Blueprint enforces that birth rule with
  # state memory; the value is the Databricks KEY-CONFIGURATION ID, not a KMS ARN.
  managed_services_customer_managed_key_id = var.managed_services_key_id
  deployment_name                          = var.deployment_name
  custom_tags                              = var.custom_tags

  lifecycle {
    # custom_tags may be modified by humans via the Databricks UI or API outside Terraform.
    # Ignore drift to avoid unintended overwrites. See the Databricks module rules Rule 3.2.
    ignore_changes = [custom_tags]
  }
}

# SINGLE-OWNER CONSOLIDATION (2026-11-10, H5-1): databricks_mws_ncc_binding is owned solely by
# dbx-workspace-network-serverless (binding + private-endpoint rules together). The input stays
# as a guarded pointer — see the variable validation for the migration path.
