mock_provider "google" {}

variables {
  project_id           = "my-test-project"
  region               = "us-central1"
  network_self_link    = "https://www.googleapis.com/compute/v1/projects/my-test-project/global/networks/test-vpc"
  subnetwork_self_link = "https://www.googleapis.com/compute/v1/projects/my-test-project/regions/us-central1/subnetworks/test-subnet"
  resource_prefix      = "databricks"
}

# ---- Resource attribute assertions ----

run "router_name_uses_prefix_suffix" {
  command = plan

  assert {
    condition     = google_compute_router.this.name == "databricks-router"
    error_message = "Cloud Router name should be <resource_prefix>-router"
  }
}

run "nat_name_uses_prefix_suffix" {
  command = plan

  assert {
    condition     = google_compute_router_nat.this.name == "databricks-nat"
    error_message = "Cloud NAT name should be <resource_prefix>-nat"
  }
}

run "nat_source_subnetwork_mode_is_list" {
  command = plan

  assert {
    condition     = google_compute_router_nat.this.source_subnetwork_ip_ranges_to_nat == "LIST_OF_SUBNETWORKS"
    error_message = "Cloud NAT source_subnetwork_ip_ranges_to_nat should be LIST_OF_SUBNETWORKS"
  }
}

run "nat_ip_allocate_option_is_auto" {
  command = plan

  assert {
    condition     = google_compute_router_nat.this.nat_ip_allocate_option == "AUTO_ONLY"
    error_message = "Cloud NAT nat_ip_allocate_option should be AUTO_ONLY"
  }
}

run "default_min_ports_per_vm" {
  command = plan

  assert {
    condition     = google_compute_router_nat.this.min_ports_per_vm == 64
    error_message = "Default min_ports_per_vm should be 64"
  }
}

run "custom_min_ports_per_vm" {
  command = plan

  variables {
    min_ports_per_vm = 256
  }

  assert {
    condition     = google_compute_router_nat.this.min_ports_per_vm == 256
    error_message = "min_ports_per_vm should reflect the input value"
  }
}

run "log_config_absent_by_default" {
  command = plan

  assert {
    # When log_config_enable = false the log_config dynamic block produces no blocks,
    # so the log_config list is empty.
    condition     = length(google_compute_router_nat.this.log_config) == 0
    error_message = "log_config block should be absent when log_config_enable is false"
  }
}

run "log_config_present_when_enabled" {
  command = plan

  variables {
    log_config_enable = true
    log_config_filter = "ALL"
  }

  assert {
    condition     = length(google_compute_router_nat.this.log_config) == 1
    error_message = "log_config block should be present when log_config_enable is true"
  }

  assert {
    condition     = google_compute_router_nat.this.log_config[0].filter == "ALL"
    error_message = "log_config filter should match log_config_filter input"
  }
}

run "router_attached_to_network" {
  command = plan

  assert {
    condition     = google_compute_router.this.network == "https://www.googleapis.com/compute/v1/projects/my-test-project/global/networks/test-vpc"
    error_message = "Cloud Router network should match the network_self_link input"
  }
}

# ---- Variable validation cases ----

run "invalid_network_self_link_rejected" {
  command = plan

  variables {
    network_self_link = "projects/my-test-project/global/networks/test-vpc"
  }

  expect_failures = [var.network_self_link]
}

run "invalid_subnetwork_self_link_rejected" {
  command = plan

  variables {
    subnetwork_self_link = "projects/my-test-project/regions/us-central1/subnetworks/test-subnet"
  }

  expect_failures = [var.subnetwork_self_link]
}

run "resource_prefix_too_long_rejected" {
  command = plan

  variables {
    resource_prefix = "this-prefix-is-way-too-long-and-exceeds-the-fifty-character-cap"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_starts_with_digit_rejected" {
  command = plan

  variables {
    resource_prefix = "1invalid"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_ends_with_hyphen_rejected" {
  command = plan

  variables {
    resource_prefix = "invalid-"
  }

  expect_failures = [var.resource_prefix]
}

run "invalid_min_ports_per_vm_rejected" {
  command = plan

  variables {
    min_ports_per_vm = 100
  }

  expect_failures = [var.min_ports_per_vm]
}

run "invalid_log_config_filter_rejected" {
  command = plan

  variables {
    log_config_filter = "INVALID_VALUE"
  }

  expect_failures = [var.log_config_filter]
}
