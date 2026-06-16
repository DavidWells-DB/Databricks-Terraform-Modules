# ---------------------------------------------------------------------------
# Compliance Security Profile
# ---------------------------------------------------------------------------

variable "compliance_security_profile_enabled" {
  type        = bool
  description = "Enable the Compliance Security Profile on the workspace. WARNING: this change is permanent and cannot be reversed once applied."
  nullable    = false
  default     = false
}

variable "compliance_standards" {
  type        = list(string)
  description = "List of compliance standards to enable. Only meaningful when compliance_security_profile_enabled = true. Valid values: CANADA_PROTECTED_B, CYBER_ESSENTIAL_PLUS, FEDRAMP_HIGH, FEDRAMP_IL5, FEDRAMP_MODERATE, GERMANY_C5, GERMANY_TISAX, HIPAA, HITRUST, IRAP_PROTECTED, ISMAP, ITAR_EAR, K_FSI, NONE, PCI_DSS."
  nullable    = false
  default     = []

  validation {
    condition = length([
      for s in var.compliance_standards : s
      if !contains([
        "CANADA_PROTECTED_B",
        "CYBER_ESSENTIAL_PLUS",
        "FEDRAMP_HIGH",
        "FEDRAMP_IL5",
        "FEDRAMP_MODERATE",
        "GERMANY_C5",
        "GERMANY_TISAX",
        "HIPAA",
        "HITRUST",
        "IRAP_PROTECTED",
        "ISMAP",
        "ITAR_EAR",
        "K_FSI",
        "NONE",
        "PCI_DSS",
      ], s)
    ]) == 0
    error_message = "compliance_standards must contain only valid values: CANADA_PROTECTED_B, CYBER_ESSENTIAL_PLUS, FEDRAMP_HIGH, FEDRAMP_IL5, FEDRAMP_MODERATE, GERMANY_C5, GERMANY_TISAX, HIPAA, HITRUST, IRAP_PROTECTED, ISMAP, ITAR_EAR, K_FSI, NONE, PCI_DSS."
  }
}

# ---------------------------------------------------------------------------
# Enhanced Security Monitoring
# ---------------------------------------------------------------------------

variable "enhanced_security_monitoring_enabled" {
  type        = bool
  description = "Enable Enhanced Security Monitoring on the workspace. Automatically enabled when compliance_security_profile_enabled = true."
  nullable    = false
  default     = false
}

# ---------------------------------------------------------------------------
# Automatic Cluster Update
# ---------------------------------------------------------------------------

variable "automatic_cluster_update_enabled" {
  type        = bool
  description = "Enable Automatic Cluster Update on the workspace. Keeps clusters patched during a maintenance window."
  nullable    = false
  default     = false
}

variable "automatic_cluster_update_restart_even_if_no_updates_available" {
  type        = bool
  description = "When automatic_cluster_update_enabled = true, force a restart during the maintenance window even if no updates are available."
  nullable    = false
  default     = false
}

variable "automatic_cluster_update_maintenance_window" {
  type = object({
    week_day_based_schedule = optional(object({
      day_of_week = string
      frequency   = string
      window_start_time = object({
        hours   = number
        minutes = number
      })
    }))
  })
  description = "Optional maintenance window for automatic cluster updates. Only used when automatic_cluster_update_enabled = true. day_of_week: MONDAY–SUNDAY (uppercase). frequency: EVERY_WEEK, FIRST_OF_MONTH, SECOND_OF_MONTH, THIRD_OF_MONTH, FOURTH_OF_MONTH, FIRST_AND_THIRD_OF_MONTH, SECOND_AND_FOURTH_OF_MONTH. hours: 0–23 (UTC). minutes: 0–59."
  nullable    = true
  default     = null

  validation {
    condition = (
      var.automatic_cluster_update_maintenance_window == null ||
      var.automatic_cluster_update_maintenance_window.week_day_based_schedule == null ||
      contains(
        ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"],
        var.automatic_cluster_update_maintenance_window.week_day_based_schedule.day_of_week
      )
    )
    error_message = "automatic_cluster_update_maintenance_window.week_day_based_schedule.day_of_week must be one of: MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY."
  }

  validation {
    condition = (
      var.automatic_cluster_update_maintenance_window == null ||
      var.automatic_cluster_update_maintenance_window.week_day_based_schedule == null ||
      contains(
        ["EVERY_WEEK", "FIRST_OF_MONTH", "SECOND_OF_MONTH", "THIRD_OF_MONTH", "FOURTH_OF_MONTH", "FIRST_AND_THIRD_OF_MONTH", "SECOND_AND_FOURTH_OF_MONTH"],
        var.automatic_cluster_update_maintenance_window.week_day_based_schedule.frequency
      )
    )
    error_message = "automatic_cluster_update_maintenance_window.week_day_based_schedule.frequency must be one of: EVERY_WEEK, FIRST_OF_MONTH, SECOND_OF_MONTH, THIRD_OF_MONTH, FOURTH_OF_MONTH, FIRST_AND_THIRD_OF_MONTH, SECOND_AND_FOURTH_OF_MONTH."
  }

  validation {
    condition = (
      var.automatic_cluster_update_maintenance_window == null ||
      var.automatic_cluster_update_maintenance_window.week_day_based_schedule == null ||
      (
        var.automatic_cluster_update_maintenance_window.week_day_based_schedule.window_start_time.hours >= 0 &&
        var.automatic_cluster_update_maintenance_window.week_day_based_schedule.window_start_time.hours <= 23
      )
    )
    error_message = "automatic_cluster_update_maintenance_window.week_day_based_schedule.window_start_time.hours must be between 0 and 23 (UTC)."
  }

  validation {
    condition = (
      var.automatic_cluster_update_maintenance_window == null ||
      var.automatic_cluster_update_maintenance_window.week_day_based_schedule == null ||
      (
        var.automatic_cluster_update_maintenance_window.week_day_based_schedule.window_start_time.minutes >= 0 &&
        var.automatic_cluster_update_maintenance_window.week_day_based_schedule.window_start_time.minutes <= 59
      )
    )
    error_message = "automatic_cluster_update_maintenance_window.week_day_based_schedule.window_start_time.minutes must be between 0 and 59."
  }
}

# ---------------------------------------------------------------------------
# Legacy Access / DBFS
# ---------------------------------------------------------------------------

variable "disable_legacy_access" {
  type        = bool
  description = "Disable legacy access on the workspace. Disables direct Hive Metastore access, external location fallback, and Databricks Runtime < 13.3 LTS. Requires Unity Catalog with a default catalog configured."
  nullable    = false
  default     = false
}

variable "disable_legacy_dbfs" {
  type        = bool
  description = "Disable legacy DBFS on the workspace. Prevents use of the root DBFS storage for new workloads."
  nullable    = false
  default     = false
}
