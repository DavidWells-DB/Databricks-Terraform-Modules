resource "google_compute_router" "this" {
  name    = "${var.resource_prefix}-router"
  project = var.project_id
  region  = var.region
  network = var.network_self_link
}

resource "google_compute_router_nat" "this" {
  name                               = "${var.resource_prefix}-nat"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.this.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  min_ports_per_vm                   = var.min_ports_per_vm

  subnetwork {
    name                    = var.subnetwork_self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  dynamic "log_config" {
    for_each = var.log_config_enable ? [1] : []
    content {
      enable = true
      filter = var.log_config_filter
    }
  }
}
