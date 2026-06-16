terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    google = {
      # 5.0+: google_compute_shared_vpc_host_project and google_compute_shared_vpc_service_project
      # stable resource support with consistent plan/apply behavior
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}
