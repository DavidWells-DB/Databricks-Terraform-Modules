output "workspace_id" {
  description = "Databricks workspace ID (numeric string). Used as the identifier within the Databricks control plane."
  value       = azapi_resource.this.output.workspace_id
}

output "workspace_url" {
  description = "Workspace URL in the format https://adb-{id}.{n}.azuredatabricks.net. Use as the host for the workspace-scoped Databricks provider."
  value       = "https://${azapi_resource.this.output.workspace_url}"
}

output "workspace_resource_id" {
  description = "Azure Resource Manager resource ID of the Databricks workspace. Used for RBAC assignments, policy, and diagnostic settings."
  value       = azapi_resource.this.id
}

output "managed_resource_group_id" {
  description = "Azure Resource Manager resource ID of the managed resource group created by Databricks for control-plane resources."
  value       = azapi_resource.this.output.managed_resource_group_id
}

output "storage_account_identity" {
  description = "Managed identity of the default storage account (principal_id, tenant_id, type). Used for Key Vault access policies when CMK is enabled."
  value       = azapi_resource.this.output.storage_account_identity
}

output "managed_disk_identity" {
  description = "Managed identity of the managed disk encryption set (principal_id, tenant_id, type). Used for Key Vault access policies when disk CMK is enabled."
  value       = azapi_resource.this.output.managed_disk_identity
}

output "disk_encryption_set_id" {
  description = "Resource ID of the Managed Disk Encryption Set. Populated only when managed_disk_cmk_key_vault_key_id is set."
  value       = azapi_resource.this.output.disk_encryption_set_id
}

output "compute_mode" {
  description = "The deployed ARM properties.computeMode (\"Hybrid\" for this module's classic workspace), read back from the ARM API. Lets consumers assert the deployed workspace type rather than trusting the config."
  value       = azapi_resource.this.output.compute_mode
}

output "is_uc_enabled" {
  description = "The deployed ARM properties.isUcEnabled, read back from the ARM API. With defaultCatalog.initialType = \"UnityCatalog\" this should read true — the in-Terraform oracle that the workspace catalog posture took effect."
  value       = azapi_resource.this.output.is_uc_enabled
}
