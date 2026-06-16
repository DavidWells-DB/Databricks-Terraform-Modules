resource "databricks_sql_endpoint" "this" {
  provider = databricks.workspace

  name                      = var.name
  cluster_size              = var.cluster_size
  warehouse_type            = var.warehouse_type
  auto_stop_mins            = var.auto_stop_mins
  min_num_clusters          = var.min_num_clusters
  max_num_clusters          = var.max_num_clusters
  spot_instance_policy      = var.spot_instance_policy
  enable_photon             = var.enable_photon
  enable_serverless_compute = var.enable_serverless_compute

  dynamic "channel" {
    for_each = var.channel != null ? [1] : []
    content {
      name = var.channel
    }
  }

  dynamic "tags" {
    for_each = length(var.tags) > 0 ? [1] : []
    content {
      dynamic "custom_tags" {
        for_each = var.tags
        content {
          key   = custom_tags.key
          value = custom_tags.value
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.max_num_clusters >= var.min_num_clusters
      error_message = "max_num_clusters (${var.max_num_clusters}) must be >= min_num_clusters (${var.min_num_clusters})."
    }
  }
}

resource "databricks_permissions" "this" {
  count    = length(var.permissions) > 0 ? 1 : 0
  provider = databricks.workspace

  sql_endpoint_id = databricks_sql_endpoint.this.id

  dynamic "access_control" {
    for_each = local.access_control_blocks
    content {
      # Determine the principal type based on format
      # Service principal: application ID (UUID format)
      # User: email address (contains @)
      # Group: name (everything else)
      service_principal_name = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", access_control.value.principal)) ? access_control.value.principal : null
      user_name              = can(regex("@", access_control.value.principal)) && !can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", access_control.value.principal)) ? access_control.value.principal : null
      group_name             = !can(regex("@", access_control.value.principal)) && !can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", access_control.value.principal)) ? access_control.value.principal : null
      permission_level       = access_control.value.permission_level
    }
  }
}
