resource "databricks_mws_network_connectivity_config" "this" {
  provider   = databricks.account
  name       = var.name
  region     = var.region
  account_id = var.databricks_account_id
}

resource "databricks_account_network_policy" "this" {
  # Created only when the caller supplies allowed_internet_destinations, which signals
  # that RESTRICTED_ACCESS mode is desired. When null, no policy is created and
  # serverless compute has unrestricted internet access from the NCC.
  count    = var.allowed_internet_destinations != null ? 1 : 0
  provider = databricks.account

  network_policy_id = var.network_policy_id

  egress = {
    network_access = {
      restriction_mode = "RESTRICTED_ACCESS"

      allowed_internet_destinations = [
        for d in var.allowed_internet_destinations : {
          destination               = d.destination
          internet_destination_type = d.internet_destination_type
        }
      ]
    }
  }
}
