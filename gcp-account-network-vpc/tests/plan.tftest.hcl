mock_provider "google" {}

mock_provider "databricks" {
  alias = "account"
}

variables {
  project_id                   = "my-test-project"
  region                       = "us-central1"
  resource_prefix              = "test"
  databricks_account_id        = "00000000-0000-0000-0000-000000000000"
  network_name                 = "test-network"
  network_cidr                 = "10.0.0.0/16"
  pod_secondary_range_cidr     = "10.1.0.0/16"
  service_secondary_range_cidr = "10.2.0.0/20"
}

# ── Variable validation ────────────────────────────────────────────────────────

run "invalid_project_id_rejected" {
  command = plan

  variables {
    project_id = "INVALID_PROJECT"
  }

  expect_failures = [var.project_id]
}

run "project_id_too_short_rejected" {
  command = plan

  variables {
    project_id = "ab"
  }

  expect_failures = [var.project_id]
}

run "project_id_too_long_rejected" {
  command = plan

  variables {
    project_id = "this-project-id-is-way-too-long-for-gcp"
  }

  expect_failures = [var.project_id]
}

run "invalid_region_rejected" {
  command = plan

  variables {
    region = "not-a-region"
  }

  expect_failures = [var.region]
}

run "resource_prefix_too_long_rejected" {
  command = plan

  variables {
    resource_prefix = "this-prefix-is-too-long-xyz"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_invalid_chars_rejected" {
  command = plan

  variables {
    resource_prefix = "UPPERCASE"
  }

  expect_failures = [var.resource_prefix]
}

run "invalid_databricks_account_id_rejected" {
  command = plan

  variables {
    databricks_account_id = "not-a-uuid"
  }

  expect_failures = [var.databricks_account_id]
}

run "network_name_empty_rejected" {
  command = plan

  variables {
    network_name = ""
  }

  expect_failures = [var.network_name]
}

run "network_name_invalid_chars_rejected" {
  command = plan

  variables {
    network_name = "invalid name with spaces"
  }

  expect_failures = [var.network_name]
}

run "invalid_network_cidr_rejected" {
  command = plan

  variables {
    network_cidr = "not-a-cidr"
  }

  expect_failures = [var.network_cidr]
}

run "network_cidr_too_small_rejected" {
  command = plan

  # /30 is smaller than the /29 minimum Databricks requires
  variables {
    network_cidr = "10.0.0.0/30"
  }

  expect_failures = [var.network_cidr]
}

run "network_cidr_too_large_rejected" {
  command = plan

  # /8 is larger than the /9 maximum Databricks requires
  variables {
    network_cidr = "10.0.0.0/8"
  }

  expect_failures = [var.network_cidr]
}

run "invalid_pod_secondary_range_cidr_rejected" {
  command = plan

  variables {
    pod_secondary_range_cidr = "not-a-cidr"
  }

  expect_failures = [var.pod_secondary_range_cidr]
}

run "invalid_service_secondary_range_cidr_rejected" {
  command = plan

  variables {
    service_secondary_range_cidr = "bad-cidr"
  }

  expect_failures = [var.service_secondary_range_cidr]
}

# ── Resource attribute checks ─────────────────────────────────────────────────

run "vpc_name_uses_resource_prefix" {
  command = plan

  assert {
    condition     = google_compute_network.this.name == "test-vpc"
    error_message = "VPC name should be <resource_prefix>-vpc"
  }
}

run "vpc_auto_create_subnetworks_disabled" {
  command = plan

  assert {
    condition     = google_compute_network.this.auto_create_subnetworks == false
    error_message = "VPC should have auto_create_subnetworks = false (custom mode required for Databricks)"
  }
}

run "subnetwork_name_uses_resource_prefix" {
  command = plan

  assert {
    condition     = google_compute_subnetwork.this.name == "test-subnet"
    error_message = "Subnetwork name should be <resource_prefix>-subnet"
  }
}

run "subnetwork_has_correct_cidr" {
  command = plan

  assert {
    condition     = google_compute_subnetwork.this.ip_cidr_range == "10.0.0.0/16"
    error_message = "Subnetwork primary CIDR should match network_cidr input"
  }
}

run "subnetwork_has_private_ip_google_access" {
  command = plan

  assert {
    condition     = google_compute_subnetwork.this.private_ip_google_access == true
    error_message = "Subnetwork should have private_ip_google_access enabled for Google API access"
  }
}

run "firewall_rule_named_correctly" {
  command = plan

  assert {
    condition     = google_compute_firewall.this.name == "db-test-subnet-ingress"
    error_message = "Firewall rule name should be db-<subnetwork_name>-ingress per Databricks documentation"
  }
}

run "firewall_rule_is_ingress" {
  command = plan

  assert {
    condition     = google_compute_firewall.this.direction == "INGRESS"
    error_message = "Databricks-required firewall rule must be INGRESS direction"
  }
}

run "secondary_range_names_use_resource_prefix" {
  command = plan

  assert {
    condition     = output.pod_secondary_range_name == "test-pods"
    error_message = "Pod secondary range name should be <resource_prefix>-pods"
  }

  assert {
    condition     = output.service_secondary_range_name == "test-services"
    error_message = "Service secondary range name should be <resource_prefix>-services"
  }
}

# ── PSC conditional logic ─────────────────────────────────────────────────────

run "no_vpc_endpoints_block_when_null" {
  command = plan

  # vpc_endpoint_ids defaults to null — no vpc_endpoints block should be included.
  assert {
    condition     = length(databricks_mws_networks.this.vpc_endpoints) == 0
    error_message = "vpc_endpoints block should be absent when vpc_endpoint_ids is null"
  }
}

run "vpc_endpoints_block_present_when_provided" {
  command = plan

  variables {
    vpc_endpoint_ids = {
      dataplane_relay = ["psc-endpoint-relay-id"]
      rest_api        = ["psc-endpoint-rest-id"]
    }
  }

  assert {
    condition     = length(databricks_mws_networks.this.vpc_endpoints) == 1
    error_message = "vpc_endpoints block should be present when vpc_endpoint_ids is provided"
  }
}
