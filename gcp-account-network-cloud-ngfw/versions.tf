terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    google = {
      # 6.0+: google_network_security_security_profile, google_network_security_security_profile_group,
      # google_network_security_firewall_endpoint, and google_network_security_firewall_endpoint_association
      # are all stable GA resources in the google provider as of 6.x.
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}
