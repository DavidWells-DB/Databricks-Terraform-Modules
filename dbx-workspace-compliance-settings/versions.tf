terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    databricks = {
      # 1.72+: databricks_disable_legacy_access_setting introduced in 1.72;
      # databricks_disable_legacy_dbfs_setting introduced in 1.73;
      # databricks_compliance_security_profile_workspace_setting,
      # databricks_enhanced_security_monitoring_workspace_setting, and
      # databricks_automatic_cluster_update_workspace_setting introduced in 1.45.
      # Lower bound set to 1.73 to cover all five resources used in this module.
      source  = "databricks/databricks"
      version = ">= 1.73"
    }
  }
}
