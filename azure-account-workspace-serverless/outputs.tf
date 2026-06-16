output "workspace_id" {
  description = "Databricks workspace ID (numeric). Used as the identifier within the Databricks control plane."
  value       = azurerm_databricks_workspace.this.workspace_id
}

output "workspace_url" {
  description = "Workspace URL in the format https://adb-{id}.{n}.azuredatabricks.net. Use as the host for the workspace-scoped Databricks provider."
  value       = "https://${azurerm_databricks_workspace.this.workspace_url}"
}

output "workspace_resource_id" {
  description = "Azure Resource Manager resource ID of the Databricks workspace. Used for RBAC assignments, policy, and diagnostic settings."
  value       = azurerm_databricks_workspace.this.id
}

output "managed_resource_group_id" {
  description = "Azure Resource Manager resource ID of the managed resource group created by Databricks for control-plane resources."
  value       = azurerm_databricks_workspace.this.managed_resource_group_id
}

output "storage_account_identity" {
  description = "Managed identity of the default storage account (principal_id, tenant_id, type). Used for Key Vault access policies when CMK is enabled."
  value       = azurerm_databricks_workspace.this.storage_account_identity
}

output "managed_disk_identity" {
  description = "Managed identity of the managed disk encryption set (principal_id, tenant_id, type). Used for Key Vault access policies when disk CMK is enabled."
  value       = azurerm_databricks_workspace.this.managed_disk_identity
}

output "disk_encryption_set_id" {
  description = "Resource ID of the Managed Disk Encryption Set. Populated only when managed_disk_cmk_key_vault_key_id is set."
  value       = azurerm_databricks_workspace.this.disk_encryption_set_id
}
