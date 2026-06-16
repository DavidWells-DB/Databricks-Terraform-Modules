mock_provider "google" {}

variables {
  organization_id   = "123456789"
  project_id        = "my-gcp-project"
  zone              = "us-central1-a"
  network_self_link = "https://www.googleapis.com/compute/v1/projects/my-gcp-project/global/networks/my-vpc"
  resource_prefix   = "databricks-ngfw"
}

# ---------------------------------------------------------------------------
# Resource attribute assertions
# ---------------------------------------------------------------------------

run "security_profile_name_uses_prefix" {
  command = plan

  assert {
    condition     = google_network_security_security_profile.this.name == "databricks-ngfw-security-profile"
    error_message = "Security profile name should be <resource_prefix>-security-profile"
  }
}

run "security_profile_group_name_uses_prefix" {
  command = plan

  assert {
    condition     = google_network_security_security_profile_group.this.name == "databricks-ngfw-security-profile-group"
    error_message = "Security profile group name should be <resource_prefix>-security-profile-group"
  }
}

run "firewall_endpoint_name_uses_prefix" {
  command = plan

  assert {
    condition     = google_network_security_firewall_endpoint.this.name == "databricks-ngfw-firewall-endpoint"
    error_message = "Firewall endpoint name should be <resource_prefix>-firewall-endpoint"
  }
}

run "firewall_endpoint_association_name_uses_prefix" {
  command = plan

  assert {
    condition     = google_network_security_firewall_endpoint_association.this.name == "databricks-ngfw-fwep-association"
    error_message = "Firewall endpoint association name should be <resource_prefix>-fwep-association"
  }
}

run "security_profile_parent_is_org" {
  command = plan

  assert {
    condition     = google_network_security_security_profile.this.parent == "organizations/123456789"
    error_message = "Security profile parent should be organizations/<organization_id>"
  }
}

run "firewall_endpoint_parent_is_org" {
  command = plan

  assert {
    condition     = google_network_security_firewall_endpoint.this.parent == "organizations/123456789"
    error_message = "Firewall endpoint parent should be organizations/<organization_id>"
  }
}

run "firewall_endpoint_association_parent_is_project" {
  command = plan

  assert {
    condition     = google_network_security_firewall_endpoint_association.this.parent == "projects/my-gcp-project"
    error_message = "Firewall endpoint association parent should be projects/<project_id>"
  }
}

run "firewall_endpoint_zone_matches_input" {
  command = plan

  assert {
    condition     = google_network_security_firewall_endpoint.this.location == "us-central1-a"
    error_message = "Firewall endpoint location should match the zone input"
  }
}

run "firewall_endpoint_association_zone_matches_input" {
  command = plan

  assert {
    condition     = google_network_security_firewall_endpoint_association.this.location == "us-central1-a"
    error_message = "Firewall endpoint association location should match the zone input"
  }
}

run "firewall_endpoint_billing_project_matches_input" {
  command = plan

  assert {
    condition     = google_network_security_firewall_endpoint.this.billing_project_id == "my-gcp-project"
    error_message = "Firewall endpoint billing_project_id should match the project_id input"
  }
}

run "security_profile_type_is_threat_prevention" {
  command = plan

  assert {
    condition     = google_network_security_security_profile.this.type == "THREAT_PREVENTION"
    error_message = "Security profile type must be THREAT_PREVENTION"
  }
}

# ---------------------------------------------------------------------------
# Variable validation: organization_id
# ---------------------------------------------------------------------------

run "invalid_org_id_non_numeric_rejected" {
  command = plan

  variables {
    organization_id = "not-a-number"
  }

  expect_failures = [var.organization_id]
}

run "invalid_org_id_empty_rejected" {
  command = plan

  variables {
    organization_id = ""
  }

  expect_failures = [var.organization_id]
}

# ---------------------------------------------------------------------------
# Variable validation: project_id
# ---------------------------------------------------------------------------

run "invalid_project_id_too_short_rejected" {
  command = plan

  variables {
    project_id = "ab"
  }

  expect_failures = [var.project_id]
}

run "invalid_project_id_uppercase_rejected" {
  command = plan

  variables {
    project_id = "MyProject"
  }

  expect_failures = [var.project_id]
}

# ---------------------------------------------------------------------------
# Variable validation: zone
# ---------------------------------------------------------------------------

run "invalid_zone_format_rejected" {
  command = plan

  variables {
    zone = "us-central1"
  }

  expect_failures = [var.zone]
}

run "invalid_zone_no_letter_rejected" {
  command = plan

  variables {
    zone = "us-central1-1"
  }

  expect_failures = [var.zone]
}

# ---------------------------------------------------------------------------
# Variable validation: network_self_link
# ---------------------------------------------------------------------------

run "invalid_network_self_link_rejected" {
  command = plan

  variables {
    network_self_link = "projects/my-project/global/networks/my-vpc"
  }

  expect_failures = [var.network_self_link]
}

# ---------------------------------------------------------------------------
# Variable validation: resource_prefix
# ---------------------------------------------------------------------------

run "invalid_resource_prefix_uppercase_rejected" {
  command = plan

  variables {
    resource_prefix = "MyPrefix"
  }

  expect_failures = [var.resource_prefix]
}

# ---------------------------------------------------------------------------
# Variable validation: severity_overrides
# ---------------------------------------------------------------------------

run "invalid_severity_override_action_rejected" {
  command = plan

  variables {
    severity_overrides = [
      {
        action   = "BLOCK"
        severity = "HIGH"
      }
    ]
  }

  expect_failures = [var.severity_overrides]
}

run "invalid_severity_override_severity_rejected" {
  command = plan

  variables {
    severity_overrides = [
      {
        action   = "DENY"
        severity = "EXTREME"
      }
    ]
  }

  expect_failures = [var.severity_overrides]
}

# ---------------------------------------------------------------------------
# Variable validation: threat_overrides
# ---------------------------------------------------------------------------

run "invalid_threat_override_action_rejected" {
  command = plan

  variables {
    threat_overrides = [
      {
        action    = "DROP"
        threat_id = "280647"
      }
    ]
  }

  expect_failures = [var.threat_overrides]
}

# ---------------------------------------------------------------------------
# Conditional: severity_overrides are passed through to the security profile
# ---------------------------------------------------------------------------

run "severity_overrides_passed_to_profile" {
  command = plan

  variables {
    severity_overrides = [
      {
        action   = "DENY"
        severity = "CRITICAL"
      }
    ]
  }

  assert {
    condition     = length(google_network_security_security_profile.this.threat_prevention_profile[0].severity_overrides) == 1
    error_message = "Expected exactly one severity override on the security profile"
  }
}
