mock_provider "databricks" {
  alias = "workspace"

  override_resource {
    target = databricks_sql_endpoint.this
    values = {
      id             = "mock-warehouse-id"
      jdbc_url       = "jdbc:databricks://mock-host:443/default"
      data_source_id = "mock-datasource-id"
      odbc_params    = {}
    }
  }
}

variables {
  name                      = "test-warehouse"
  cluster_size              = "Small"
  warehouse_type            = "PRO"
  auto_stop_mins            = 10
  min_num_clusters          = 1
  max_num_clusters          = 1
  spot_instance_policy      = "COST_OPTIMIZED"
  channel                   = "CURRENT"
  enable_photon             = true
  enable_serverless_compute = false
  permissions               = {}
  tags                      = {}
}

run "valid_cluster_size_small_accepted" {
  command = plan

  assert {
    condition     = databricks_sql_endpoint.this.cluster_size == "Small"
    error_message = "cluster_size should be Small"
  }
}

run "valid_cluster_size_2x_small_accepted" {
  command = plan

  variables {
    cluster_size = "2X-Small"
  }

  assert {
    condition     = databricks_sql_endpoint.this.cluster_size == "2X-Small"
    error_message = "cluster_size should be 2X-Small"
  }
}

run "valid_cluster_size_4x_large_accepted" {
  command = plan

  variables {
    cluster_size = "4X-Large"
  }

  assert {
    condition     = databricks_sql_endpoint.this.cluster_size == "4X-Large"
    error_message = "cluster_size should be 4X-Large"
  }
}

run "invalid_cluster_size_rejected" {
  command = plan

  variables {
    cluster_size = "Huge"
  }

  expect_failures = [var.cluster_size]
}

run "valid_warehouse_type_classic_accepted" {
  command = plan

  variables {
    warehouse_type = "CLASSIC"
  }

  assert {
    condition     = databricks_sql_endpoint.this.warehouse_type == "CLASSIC"
    error_message = "warehouse_type should be CLASSIC"
  }
}

run "invalid_warehouse_type_rejected" {
  command = plan

  variables {
    warehouse_type = "ULTRA"
  }

  expect_failures = [var.warehouse_type]
}

run "invalid_warehouse_type_serverless_rejected" {
  command = plan

  variables {
    warehouse_type = "SERVERLESS"
  }

  expect_failures = [var.warehouse_type]
}

run "valid_spot_policy_cost_optimized_accepted" {
  command = plan

  assert {
    condition     = databricks_sql_endpoint.this.spot_instance_policy == "COST_OPTIMIZED"
    error_message = "spot_instance_policy should be COST_OPTIMIZED"
  }
}

run "valid_spot_policy_reliability_accepted" {
  command = plan

  variables {
    spot_instance_policy = "RELIABILITY_OPTIMIZED"
  }

  assert {
    condition     = databricks_sql_endpoint.this.spot_instance_policy == "RELIABILITY_OPTIMIZED"
    error_message = "spot_instance_policy should be RELIABILITY_OPTIMIZED"
  }
}

run "invalid_spot_policy_rejected" {
  command = plan

  variables {
    spot_instance_policy = "INVALID_POLICY"
  }

  expect_failures = [var.spot_instance_policy]
}

run "valid_channel_current_accepted" {
  command = plan

  assert {
    condition     = databricks_sql_endpoint.this.channel[0].name == "CURRENT"
    error_message = "channel should be CURRENT"
  }
}

run "valid_channel_preview_accepted" {
  command = plan

  variables {
    channel = "PREVIEW"
  }

  assert {
    condition     = databricks_sql_endpoint.this.channel[0].name == "PREVIEW"
    error_message = "channel should be PREVIEW"
  }
}

run "invalid_channel_rejected" {
  command = plan

  variables {
    channel = "BETA"
  }

  expect_failures = [var.channel]
}

run "auto_stop_zero_accepted" {
  command = plan

  variables {
    auto_stop_mins = 0
  }

  assert {
    condition     = databricks_sql_endpoint.this.auto_stop_mins == 0
    error_message = "auto_stop_mins should be 0"
  }
}

run "auto_stop_negative_rejected" {
  command = plan

  variables {
    auto_stop_mins = -1
  }

  expect_failures = [var.auto_stop_mins]
}

run "min_clusters_one_accepted" {
  command = plan

  assert {
    condition     = databricks_sql_endpoint.this.min_num_clusters == 1
    error_message = "min_num_clusters should be 1"
  }
}

run "min_clusters_zero_rejected" {
  command = plan

  variables {
    min_num_clusters = 0
  }

  expect_failures = [var.min_num_clusters]
}

run "max_clusters_equal_to_min_accepted" {
  command = plan

  variables {
    min_num_clusters = 2
    max_num_clusters = 2
  }

  assert {
    condition     = databricks_sql_endpoint.this.max_num_clusters == 2
    error_message = "max_num_clusters should equal min_num_clusters"
  }
}

run "max_clusters_less_than_min_rejected" {
  command = plan

  variables {
    min_num_clusters = 3
    max_num_clusters = 2
  }

  expect_failures = [databricks_sql_endpoint.this]
}

run "valid_permission_can_use_accepted" {
  command = plan

  variables {
    permissions = {
      "users" = "CAN_USE"
    }
  }

  assert {
    condition     = length(databricks_permissions.this) == 1
    error_message = "permissions resource should be created when permissions are provided"
  }
}

run "valid_permission_is_owner_accepted" {
  command = plan

  variables {
    permissions = {
      "admins" = "IS_OWNER"
    }
  }

  assert {
    condition     = length(databricks_permissions.this) == 1
    error_message = "permissions resource should be created"
  }
}

run "invalid_permission_level_rejected" {
  command = plan

  variables {
    permissions = {
      "users" = "CAN_DELETE"
    }
  }

  expect_failures = [var.permissions]
}

run "empty_permissions_no_resource_created" {
  command = plan

  assert {
    condition     = length(databricks_permissions.this) == 0
    error_message = "permissions resource should not be created when permissions map is empty"
  }
}

run "warehouse_name_set_correctly" {
  command = plan

  assert {
    condition     = databricks_sql_endpoint.this.name == "test-warehouse"
    error_message = "warehouse name should match input variable"
  }
}

run "enable_photon_true_applied" {
  command = plan

  assert {
    condition     = databricks_sql_endpoint.this.enable_photon == true
    error_message = "enable_photon = true should be applied to the warehouse"
  }
}

run "serverless_disabled_by_default" {
  command = plan

  assert {
    condition     = databricks_sql_endpoint.this.enable_serverless_compute == false
    error_message = "enable_serverless_compute should default to false"
  }
}
