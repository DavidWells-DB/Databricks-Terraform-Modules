output "compliance_security_profile_enabled" {
  description = "Whether the Compliance Security Profile was applied by this module. True when compliance_security_profile_enabled = true. Useful as a signal for downstream modules that need to know whether CSP is active."
  value       = length(databricks_compliance_security_profile_workspace_setting.this) > 0
}

output "compliance_standards" {
  description = "Compliance standards passed to the Compliance Security Profile. Empty list when compliance_security_profile_enabled = false."
  value       = var.compliance_security_profile_enabled ? var.compliance_standards : []
}

output "enhanced_security_monitoring_enabled" {
  description = "Whether Enhanced Security Monitoring was applied by this module."
  value       = length(databricks_enhanced_security_monitoring_workspace_setting.this) > 0
}

output "automatic_cluster_update_enabled" {
  description = "Whether Automatic Cluster Update was applied by this module."
  value       = length(databricks_automatic_cluster_update_workspace_setting.this) > 0
}

output "legacy_access_disabled" {
  description = "Whether legacy access was disabled by this module."
  value       = length(databricks_disable_legacy_access_setting.this) > 0
}

output "legacy_dbfs_disabled" {
  description = "Whether legacy DBFS was disabled by this module."
  value       = length(databricks_disable_legacy_dbfs_setting.this) > 0
}
