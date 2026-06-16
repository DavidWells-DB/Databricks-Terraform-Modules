# ---------------------------------------------------------------------------
# Workspace PSC endpoint
# ---------------------------------------------------------------------------

resource "google_compute_address" "workspace" {
  project      = var.project_id
  name         = "${var.resource_prefix}-workspace-psc-ip"
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = var.psc_subnet_self_link
  purpose      = "GCE_ENDPOINT"
}

resource "google_compute_forwarding_rule" "workspace" {
  project                 = var.project_id
  name                    = "${var.resource_prefix}-workspace-psc"
  region                  = var.region
  network                 = var.network_self_link
  ip_address              = google_compute_address.workspace.self_link
  target                  = local.workspace_psc_attachment
  load_balancing_scheme   = ""
  allow_psc_global_access = true
}

# ---------------------------------------------------------------------------
# SCC relay PSC endpoint
# ---------------------------------------------------------------------------

resource "google_compute_address" "relay" {
  project      = var.project_id
  name         = "${var.resource_prefix}-relay-psc-ip"
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = var.psc_subnet_self_link
  purpose      = "GCE_ENDPOINT"
}

resource "google_compute_forwarding_rule" "relay" {
  project                 = var.project_id
  name                    = "${var.resource_prefix}-relay-psc"
  region                  = var.region
  network                 = var.network_self_link
  ip_address              = google_compute_address.relay.self_link
  target                  = local.relay_psc_attachment
  load_balancing_scheme   = ""
  allow_psc_global_access = true
}

# ---------------------------------------------------------------------------
# Private DNS zone for gcp.databricks.com
# Resolves workspace URLs and the regional PSC intermediate hostname to the
# workspace PSC endpoint IP.
# ---------------------------------------------------------------------------

resource "google_dns_managed_zone" "databricks" {
  project     = var.project_id
  name        = "${var.resource_prefix}-databricks-psc"
  dns_name    = "gcp.databricks.com."
  description = "Private DNS zone routing gcp.databricks.com traffic through the Databricks PSC workspace endpoint."
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = var.network_self_link
    }
  }
}

# Wildcard A record: resolves all *.gcp.databricks.com addresses (workspace URLs,
# dp-prefixed names, and the regional PSC intermediate hostname) to the workspace
# PSC endpoint IP.
resource "google_dns_record_set" "workspace_wildcard" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.databricks.name
  name         = "*.gcp.databricks.com."
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_address.workspace.address]
}

# Root A record for gcp.databricks.com itself.
resource "google_dns_record_set" "workspace_root" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.databricks.name
  name         = "gcp.databricks.com."
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_address.workspace.address]
}

# SCC relay A record: resolves tunnel.<region>.gcp.databricks.com to the relay IP.
resource "google_dns_record_set" "relay" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.databricks.name
  name         = "tunnel.${var.region}.gcp.databricks.com."
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_address.relay.address]
}

# ---------------------------------------------------------------------------
# Databricks account-side registration
# ---------------------------------------------------------------------------

resource "databricks_mws_vpc_endpoint" "workspace" {
  provider          = databricks.account
  account_id        = var.databricks_account_id
  vpc_endpoint_name = "${var.resource_prefix}-workspace-psc"

  gcp_vpc_endpoint_info {
    project_id        = var.project_id
    psc_endpoint_name = google_compute_forwarding_rule.workspace.name
    endpoint_region   = var.region
  }
}

resource "databricks_mws_vpc_endpoint" "relay" {
  provider          = databricks.account
  account_id        = var.databricks_account_id
  vpc_endpoint_name = "${var.resource_prefix}-relay-psc"

  gcp_vpc_endpoint_info {
    project_id        = var.project_id
    psc_endpoint_name = google_compute_forwarding_rule.relay.name
    endpoint_region   = var.region
  }
}

resource "databricks_mws_private_access_settings" "this" {
  provider                     = databricks.account
  account_id                   = var.databricks_account_id
  private_access_settings_name = local.pas_name
  region                       = var.region
  public_access_enabled        = var.public_access_enabled
  private_access_level         = var.private_access_level

  allowed_vpc_endpoint_ids = (
    var.private_access_level == "ENDPOINT"
    ? var.allowed_vpc_endpoint_ids
    : []
  )
}
