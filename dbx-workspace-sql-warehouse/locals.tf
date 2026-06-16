locals {
  # Build access_control blocks for databricks_permissions
  access_control_blocks = flatten([
    for principal, level in var.permissions : {
      principal        = principal
      permission_level = level
    }
  ])
}
