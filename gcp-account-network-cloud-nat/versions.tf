terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    google = {
      # 5.0+: stable google_compute_router and google_compute_router_nat behavior used by this module
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}
