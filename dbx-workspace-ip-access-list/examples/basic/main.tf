terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.39"
    }
  }
}

provider "databricks" {
  alias         = "workspace"
  host          = var.databricks_workspace_host
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "ip_access_list" {
  source = "../.."

  providers = {
    databricks.workspace = databricks.workspace
  }

  allow_list_label = "corporate-networks"
  allow_list_cidrs = var.allow_list_cidrs

  # Optional: uncomment and set block_list_cidrs to also create a BLOCK list.
  # block_list_cidrs = ["198.51.100.0/24"]
  # block_list_label = "blocked-ranges"
}

variable "databricks_workspace_host" {
  type        = string
  description = "Databricks workspace URL. Example: https://adb-1234567890123456.7.azuredatabricks.net"
}

variable "databricks_client_id" {
  type        = string
  description = "Databricks workspace-level service principal application ID (OAuth M2M)."
}

variable "databricks_client_secret" {
  type        = string
  description = "Databricks workspace-level service principal secret (OAuth M2M)."
  sensitive   = true
}

variable "allow_list_cidrs" {
  type        = list(string)
  description = "List of IPv4 CIDR blocks or individual IPs to allow access to the workspace."
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

output "allow_list_id" {
  value = module.ip_access_list.allow_list_id
}

output "block_list_id" {
  value = module.ip_access_list.block_list_id
}
