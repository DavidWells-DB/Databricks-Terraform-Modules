# Compliance Security Profile — permanent once enabled; cannot be disabled.
# Requires Enterprise tier. On Azure, use azurerm_databricks_workspace instead.
resource "databricks_compliance_security_profile_workspace_setting" "this" {
  count = var.compliance_security_profile_enabled ? 1 : 0

  compliance_security_profile_workspace {
    is_enabled           = true
    compliance_standards = var.compliance_standards
  }
}

# Enhanced Security Monitoring — automatically active when compliance profile is enabled.
# Requires Enterprise tier. On Azure, use azurerm_databricks_workspace instead.
resource "databricks_enhanced_security_monitoring_workspace_setting" "this" {
  count = var.enhanced_security_monitoring_enabled ? 1 : 0

  enhanced_security_monitoring_workspace {
    is_enabled = true
  }
}

# Automatic Cluster Update — keeps clusters patched; requires Enterprise tier.
# On Azure, use azurerm_databricks_workspace instead.
resource "databricks_automatic_cluster_update_workspace_setting" "this" {
  count = var.automatic_cluster_update_enabled ? 1 : 0

  automatic_cluster_update_workspace {
    enabled                              = true
    restart_even_if_no_updates_available = var.automatic_cluster_update_restart_even_if_no_updates_available

    dynamic "maintenance_window" {
      for_each = var.automatic_cluster_update_maintenance_window != null ? [var.automatic_cluster_update_maintenance_window] : []
      content {
        dynamic "week_day_based_schedule" {
          for_each = maintenance_window.value.week_day_based_schedule != null ? [maintenance_window.value.week_day_based_schedule] : []
          content {
            day_of_week = week_day_based_schedule.value.day_of_week
            frequency   = week_day_based_schedule.value.frequency
            window_start_time {
              hours   = week_day_based_schedule.value.window_start_time.hours
              minutes = week_day_based_schedule.value.window_start_time.minutes
            }
          }
        }
      }
    }
  }
}

# Disable Legacy Access — disables direct Hive Metastore access, external location fallback,
# and runtimes < 13.3 LTS. Requires Unity Catalog with a default catalog set. Premium tier.
resource "databricks_disable_legacy_access_setting" "this" {
  count = var.disable_legacy_access ? 1 : 0

  disable_legacy_access {
    value = true
  }
}

# Disable Legacy DBFS — prevents use of root DBFS for new workloads. Premium tier.
resource "databricks_disable_legacy_dbfs_setting" "this" {
  count = var.disable_legacy_dbfs ? 1 : 0

  disable_legacy_dbfs {
    value = true
  }
}
