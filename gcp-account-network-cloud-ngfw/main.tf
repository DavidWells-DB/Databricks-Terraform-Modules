# Cloud NGFW security profile — defines threat-prevention behavior for VPC egress inspection.
# Organization-scoped; location is always "global" for Cloud NGFW security profiles.
resource "google_network_security_security_profile" "this" {
  name     = "${var.resource_prefix}-security-profile"
  parent   = local.org_parent
  type     = "THREAT_PREVENTION"
  location = "global"

  threat_prevention_profile {
    dynamic "severity_overrides" {
      for_each = var.severity_overrides
      content {
        action   = severity_overrides.value.action
        severity = severity_overrides.value.severity
      }
    }

    dynamic "threat_overrides" {
      for_each = var.threat_overrides
      content {
        action    = threat_overrides.value.action
        threat_id = threat_overrides.value.threat_id
      }
    }
  }

  labels = var.labels
}

# Cloud NGFW security profile group — container that references the security profile.
# The firewall endpoint association references this group via firewall policy rules.
resource "google_network_security_security_profile_group" "this" {
  name                      = "${var.resource_prefix}-security-profile-group"
  parent                    = local.org_parent
  location                  = "global"
  threat_prevention_profile = google_network_security_security_profile.this.id

  labels = var.labels
}

# Cloud NGFW firewall endpoint — zonal resource providing the Layer 7 inspection capacity.
# Billing is charged to the project specified by billing_project_id.
# Creation takes up to 60 minutes; Terraform will wait for the ACTIVE state.
resource "google_network_security_firewall_endpoint" "this" {
  name               = "${var.resource_prefix}-firewall-endpoint"
  parent             = local.org_parent
  location           = var.zone
  billing_project_id = var.project_id

  labels = var.labels
}

# Cloud NGFW firewall endpoint association — links the firewall endpoint to the VPC network
# in the same zone. After this association is active, firewall policy rules referencing the
# security profile group will steer matched traffic to the firewall endpoint for inspection.
resource "google_network_security_firewall_endpoint_association" "this" {
  name              = "${var.resource_prefix}-fwep-association"
  parent            = local.project_parent
  location          = var.zone
  network           = var.network_self_link
  firewall_endpoint = google_network_security_firewall_endpoint.this.id

  labels = var.labels
}
