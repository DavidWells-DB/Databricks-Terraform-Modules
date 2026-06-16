mock_provider "google" {}

mock_provider "databricks" {
  alias = "account"
}

variables {
  databricks_account_id = "00000000-0000-0000-0000-000000000000"
  project_id            = "my-gcp-project"
  region                = "us-central1"
  network_self_link     = "projects/my-gcp-project/global/networks/my-vpc"
  psc_subnet_self_link  = "projects/my-gcp-project/regions/us-central1/subnetworks/my-psc-subnet"
  resource_prefix       = "dbx-psc"
}

# ---------------------------------------------------------------------------
# Region -> service attachment URI resolution
# ---------------------------------------------------------------------------

run "us_central1_resolves_workspace_attachment" {
  command = plan

  assert {
    condition     = output.workspace_psc_service_attachment == "projects/gcp-prod-general/regions/us-central1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    error_message = "us-central1 workspace attachment URI mismatch"
  }
}

run "us_central1_resolves_relay_attachment" {
  command = plan

  assert {
    condition     = output.relay_psc_service_attachment == "projects/prod-gcp-us-central1/regions/us-central1/serviceAttachments/ngrok-psc-endpoint"
    error_message = "us-central1 relay attachment URI mismatch"
  }
}

run "europe_west1_resolves_workspace_attachment" {
  command = plan

  variables {
    region = "europe-west1"
  }

  assert {
    condition     = output.workspace_psc_service_attachment == "projects/general-prod-europewest1-01/regions/europe-west1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    error_message = "europe-west1 workspace attachment URI mismatch"
  }
}

run "europe_west1_resolves_relay_attachment" {
  command = plan

  variables {
    region = "europe-west1"
  }

  assert {
    condition     = output.relay_psc_service_attachment == "projects/prod-gcp-europe-west1/regions/europe-west1/serviceAttachments/ngrok-psc-endpoint"
    error_message = "europe-west1 relay attachment URI mismatch"
  }
}

run "asia_northeast1_resolves_workspace_attachment" {
  command = plan

  variables {
    region = "asia-northeast1"
  }

  assert {
    condition     = output.workspace_psc_service_attachment == "projects/general-prod-asianortheast1-01/regions/asia-northeast1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    error_message = "asia-northeast1 workspace attachment URI mismatch"
  }
}

# ---------------------------------------------------------------------------
# Service attachment override inputs
# ---------------------------------------------------------------------------

run "workspace_attachment_override_propagates" {
  command = plan

  variables {
    workspace_psc_service_attachment = "projects/custom-project/regions/us-central1/serviceAttachments/custom-workspace"
  }

  assert {
    condition     = output.workspace_psc_service_attachment == "projects/custom-project/regions/us-central1/serviceAttachments/custom-workspace"
    error_message = "workspace_psc_service_attachment override did not propagate to output"
  }
}

run "relay_attachment_override_propagates" {
  command = plan

  variables {
    relay_psc_service_attachment = "projects/custom-project/regions/us-central1/serviceAttachments/custom-relay"
  }

  assert {
    condition     = output.relay_psc_service_attachment == "projects/custom-project/regions/us-central1/serviceAttachments/custom-relay"
    error_message = "relay_psc_service_attachment override did not propagate to output"
  }
}

# ---------------------------------------------------------------------------
# Variable validations
# ---------------------------------------------------------------------------

run "invalid_region_rejected" {
  command = plan

  variables {
    region = "us-west2"
  }

  expect_failures = [var.region]
}

run "invalid_region_rejected_nonexistent" {
  command = plan

  variables {
    region = "not-a-region"
  }

  expect_failures = [var.region]
}

run "invalid_private_access_level_rejected" {
  command = plan

  variables {
    private_access_level = "NONE"
  }

  expect_failures = [var.private_access_level]
}

run "resource_prefix_empty_rejected" {
  command = plan

  variables {
    resource_prefix = ""
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_too_long_rejected" {
  command = plan

  variables {
    resource_prefix = "this-prefix-is-way-too-long-for-gcp"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_uppercase_rejected" {
  command = plan

  variables {
    resource_prefix = "MyPrefix"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_starts_with_digit_rejected" {
  command = plan

  variables {
    resource_prefix = "1bad"
  }

  expect_failures = [var.resource_prefix]
}

# ---------------------------------------------------------------------------
# Resource attribute checks
# ---------------------------------------------------------------------------

run "workspace_forwarding_rule_name_uses_prefix" {
  command = plan

  assert {
    condition     = google_compute_forwarding_rule.workspace.name == "dbx-psc-workspace-psc"
    error_message = "Workspace forwarding rule name should be <resource_prefix>-workspace-psc"
  }
}

run "relay_forwarding_rule_name_uses_prefix" {
  command = plan

  assert {
    condition     = google_compute_forwarding_rule.relay.name == "dbx-psc-relay-psc"
    error_message = "Relay forwarding rule name should be <resource_prefix>-relay-psc"
  }
}

run "dns_zone_name_uses_prefix" {
  command = plan

  assert {
    condition     = output.dns_zone_name == "dbx-psc-databricks-psc"
    error_message = "DNS zone name should be <resource_prefix>-databricks-psc"
  }
}

run "default_pas_name_uses_prefix" {
  command = plan

  assert {
    condition     = databricks_mws_private_access_settings.this.private_access_settings_name == "dbx-psc-pas"
    error_message = "Default PAS name should be <resource_prefix>-pas"
  }
}

run "custom_pas_name_propagates" {
  command = plan

  variables {
    private_access_settings_name = "my-custom-pas"
  }

  assert {
    condition     = databricks_mws_private_access_settings.this.private_access_settings_name == "my-custom-pas"
    error_message = "Custom private_access_settings_name did not propagate to the PAS resource"
  }
}

run "pas_region_matches_input" {
  command = plan

  assert {
    condition     = databricks_mws_private_access_settings.this.region == "us-central1"
    error_message = "PAS region should match var.region"
  }
}

run "workspace_address_region_matches_input" {
  command = plan

  assert {
    condition     = google_compute_address.workspace.region == "us-central1"
    error_message = "Workspace PSC address region should match var.region"
  }
}

run "relay_address_region_matches_input" {
  command = plan

  assert {
    condition     = google_compute_address.relay.region == "us-central1"
    error_message = "Relay PSC address region should match var.region"
  }
}
