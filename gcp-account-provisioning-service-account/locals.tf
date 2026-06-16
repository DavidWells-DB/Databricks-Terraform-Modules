locals {
  # Service account ID: GCP limits account IDs to 6-30 lowercase alphanumeric + hyphen.
  # We append a fixed suffix so that any resource_prefix of up to 20 chars stays within the limit.
  service_account_id = "${var.resource_prefix}-dbx-provisioner"

  # Custom role ID: GCP role IDs use camelCase or underscores; hyphens are not allowed.
  # We normalise the prefix by replacing hyphens with underscores before appending the suffix.
  custom_role_id = "${replace(var.resource_prefix, "-", "_")}DbxProvisionerRole"

  # Display name shown in the GCP IAM console.
  service_account_display_name = "Databricks Workspace Provisioner (${var.resource_prefix})"
}
