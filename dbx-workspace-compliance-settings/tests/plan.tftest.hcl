mock_provider "databricks" {}

# Default variables: all flags off, no compliance standards, no maintenance window.
variables {
  compliance_security_profile_enabled                           = false
  compliance_standards                                          = []
  enhanced_security_monitoring_enabled                          = false
  automatic_cluster_update_enabled                              = false
  automatic_cluster_update_restart_even_if_no_updates_available = false
  automatic_cluster_update_maintenance_window                   = null
  disable_legacy_access                                         = false
  disable_legacy_dbfs                                           = false
}

# ---------------------------------------------------------------------------
# All flags off — no resources are created
# ---------------------------------------------------------------------------

run "all_flags_off_produces_no_resources" {
  command = plan

  assert {
    condition     = length(databricks_compliance_security_profile_workspace_setting.this) == 0
    error_message = "CSP resource should not be created when compliance_security_profile_enabled = false"
  }

  assert {
    condition     = length(databricks_enhanced_security_monitoring_workspace_setting.this) == 0
    error_message = "ESM resource should not be created when enhanced_security_monitoring_enabled = false"
  }

  assert {
    condition     = length(databricks_automatic_cluster_update_workspace_setting.this) == 0
    error_message = "ACU resource should not be created when automatic_cluster_update_enabled = false"
  }

  assert {
    condition     = length(databricks_disable_legacy_access_setting.this) == 0
    error_message = "Disable legacy access resource should not be created when disable_legacy_access = false"
  }

  assert {
    condition     = length(databricks_disable_legacy_dbfs_setting.this) == 0
    error_message = "Disable legacy DBFS resource should not be created when disable_legacy_dbfs = false"
  }
}

run "all_flags_off_outputs_are_false" {
  command = plan

  assert {
    condition     = output.compliance_security_profile_enabled == false
    error_message = "compliance_security_profile_enabled output should be false when flag is off"
  }

  assert {
    condition     = output.enhanced_security_monitoring_enabled == false
    error_message = "enhanced_security_monitoring_enabled output should be false when flag is off"
  }

  assert {
    condition     = output.automatic_cluster_update_enabled == false
    error_message = "automatic_cluster_update_enabled output should be false when flag is off"
  }

  assert {
    condition     = output.legacy_access_disabled == false
    error_message = "legacy_access_disabled output should be false when flag is off"
  }

  assert {
    condition     = output.legacy_dbfs_disabled == false
    error_message = "legacy_dbfs_disabled output should be false when flag is off"
  }
}

# ---------------------------------------------------------------------------
# CSP enabled — resource is created; output reflects true
# ---------------------------------------------------------------------------

run "csp_enabled_creates_resource" {
  command = plan

  variables {
    compliance_security_profile_enabled = true
    compliance_standards                = ["HIPAA"]
  }

  assert {
    condition     = length(databricks_compliance_security_profile_workspace_setting.this) == 1
    error_message = "CSP resource should be created when compliance_security_profile_enabled = true"
  }

  assert {
    condition     = output.compliance_security_profile_enabled == true
    error_message = "compliance_security_profile_enabled output should be true when flag is on"
  }

  assert {
    condition     = output.compliance_standards == tolist(["HIPAA"])
    error_message = "compliance_standards output should reflect the standards passed in"
  }
}

# ---------------------------------------------------------------------------
# ESM enabled — resource is created
# ---------------------------------------------------------------------------

run "esm_enabled_creates_resource" {
  command = plan

  variables {
    enhanced_security_monitoring_enabled = true
  }

  assert {
    condition     = length(databricks_enhanced_security_monitoring_workspace_setting.this) == 1
    error_message = "ESM resource should be created when enhanced_security_monitoring_enabled = true"
  }

  assert {
    condition     = output.enhanced_security_monitoring_enabled == true
    error_message = "enhanced_security_monitoring_enabled output should be true when flag is on"
  }
}

# ---------------------------------------------------------------------------
# ACU enabled with maintenance window
# ---------------------------------------------------------------------------

run "acu_enabled_with_maintenance_window" {
  command = plan

  variables {
    automatic_cluster_update_enabled = true
    automatic_cluster_update_maintenance_window = {
      week_day_based_schedule = {
        day_of_week = "SUNDAY"
        frequency   = "EVERY_WEEK"
        window_start_time = {
          hours   = 2
          minutes = 0
        }
      }
    }
  }

  assert {
    condition     = length(databricks_automatic_cluster_update_workspace_setting.this) == 1
    error_message = "ACU resource should be created when automatic_cluster_update_enabled = true"
  }

  assert {
    condition     = output.automatic_cluster_update_enabled == true
    error_message = "automatic_cluster_update_enabled output should be true when flag is on"
  }
}

# ---------------------------------------------------------------------------
# Legacy access and DBFS disabled
# ---------------------------------------------------------------------------

run "legacy_settings_disabled_creates_resources" {
  command = plan

  variables {
    disable_legacy_access = true
    disable_legacy_dbfs   = true
  }

  assert {
    condition     = length(databricks_disable_legacy_access_setting.this) == 1
    error_message = "Legacy access resource should be created when disable_legacy_access = true"
  }

  assert {
    condition     = length(databricks_disable_legacy_dbfs_setting.this) == 1
    error_message = "Legacy DBFS resource should be created when disable_legacy_dbfs = true"
  }

  assert {
    condition     = output.legacy_access_disabled == true
    error_message = "legacy_access_disabled output should be true when flag is on"
  }

  assert {
    condition     = output.legacy_dbfs_disabled == true
    error_message = "legacy_dbfs_disabled output should be true when flag is on"
  }
}

# ---------------------------------------------------------------------------
# Variable validation — compliance_standards invalid value
# ---------------------------------------------------------------------------

run "invalid_compliance_standard_rejected" {
  command = plan

  variables {
    compliance_security_profile_enabled = true
    compliance_standards                = ["INVALID_STANDARD"]
  }

  expect_failures = [var.compliance_standards]
}

# ---------------------------------------------------------------------------
# Variable validation — maintenance window day_of_week
# ---------------------------------------------------------------------------

run "invalid_maintenance_window_day_of_week_rejected" {
  command = plan

  variables {
    automatic_cluster_update_enabled = true
    automatic_cluster_update_maintenance_window = {
      week_day_based_schedule = {
        day_of_week = "monday" # lowercase — invalid
        frequency   = "EVERY_WEEK"
        window_start_time = {
          hours   = 2
          minutes = 0
        }
      }
    }
  }

  expect_failures = [var.automatic_cluster_update_maintenance_window]
}

# ---------------------------------------------------------------------------
# Variable validation — maintenance window frequency
# ---------------------------------------------------------------------------

run "invalid_maintenance_window_frequency_rejected" {
  command = plan

  variables {
    automatic_cluster_update_enabled = true
    automatic_cluster_update_maintenance_window = {
      week_day_based_schedule = {
        day_of_week = "MONDAY"
        frequency   = "DAILY" # invalid
        window_start_time = {
          hours   = 2
          minutes = 0
        }
      }
    }
  }

  expect_failures = [var.automatic_cluster_update_maintenance_window]
}

# ---------------------------------------------------------------------------
# Variable validation — maintenance window hours out of range
# ---------------------------------------------------------------------------

run "invalid_maintenance_window_hours_rejected" {
  command = plan

  variables {
    automatic_cluster_update_enabled = true
    automatic_cluster_update_maintenance_window = {
      week_day_based_schedule = {
        day_of_week = "MONDAY"
        frequency   = "EVERY_WEEK"
        window_start_time = {
          hours   = 25 # out of range
          minutes = 0
        }
      }
    }
  }

  expect_failures = [var.automatic_cluster_update_maintenance_window]
}

# ---------------------------------------------------------------------------
# Variable validation — maintenance window minutes out of range
# ---------------------------------------------------------------------------

run "invalid_maintenance_window_minutes_rejected" {
  command = plan

  variables {
    automatic_cluster_update_enabled = true
    automatic_cluster_update_maintenance_window = {
      week_day_based_schedule = {
        day_of_week = "MONDAY"
        frequency   = "EVERY_WEEK"
        window_start_time = {
          hours   = 2
          minutes = 60 # out of range
        }
      }
    }
  }

  expect_failures = [var.automatic_cluster_update_maintenance_window]
}
