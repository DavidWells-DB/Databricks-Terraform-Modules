terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.60"
    }
  }
}

provider "databricks" {
  alias         = "account"
  host          = var.databricks_account_host
  account_id    = var.databricks_account_id
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "network_policy" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  policy_name = "example-restricted-policy"
  egress_mode = "ALLOW_LIST"

  allowed_internet_destinations = [
    {
      destination               = "10.0.0.0/8"
      internet_destination_type = "CIDR"
    },
    {
      destination               = "pypi.org"
      internet_destination_type = "FQDN"
    }
  ]

  allowed_storage_destinations = [
    {
      bucket_name              = "my-data-lake-bucket"
      azure_storage_account    = null
      azure_storage_service    = null
      region                   = "us-west-2"
      storage_destination_type = null
    }
  ]
}

variable "databricks_account_host" {
  type        = string
  description = "Databricks account host. Commercial: https://accounts.cloud.databricks.com. GovCloud civilian: https://accounts.cloud.databricks.us. DoD: https://accounts-dod.cloud.databricks.mil."
  default     = "https://accounts.cloud.databricks.com"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID."
}

variable "databricks_client_id" {
  type        = string
  description = "Databricks account-level service principal application ID (OAuth M2M)."
}

variable "databricks_client_secret" {
  type        = string
  description = "Databricks account-level service principal secret (OAuth M2M)."
  sensitive   = true
}

output "network_policy_id" {
  value = module.network_policy.network_policy_id
}

output "policy_name" {
  value = module.network_policy.policy_name
}

output "egress_mode" {
  value = module.network_policy.egress_mode
}
