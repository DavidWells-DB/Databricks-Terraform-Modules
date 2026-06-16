resource "databricks_account_network_policy" "this" {
  provider = databricks.account

  network_policy_id = var.policy_name

  egress = {
    network_access = {
      restriction_mode = var.egress_mode

      allowed_internet_destinations = [
        for dest in var.allowed_internet_destinations : {
          destination               = dest.destination
          internet_destination_type = dest.internet_destination_type
        }
      ]

      allowed_storage_destinations = [
        for dest in var.allowed_storage_destinations : {
          bucket_name              = dest.bucket_name
          azure_storage_account    = dest.azure_storage_account
          azure_storage_service    = dest.azure_storage_service
          region                   = dest.region
          storage_destination_type = dest.storage_destination_type
        }
      ]
    }
  }
}
