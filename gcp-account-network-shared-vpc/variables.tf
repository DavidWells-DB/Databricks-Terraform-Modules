variable "host_project_id" {
  type        = string
  description = "GCP project ID of the Shared VPC host project. This project will be configured as the Shared VPC host."
  nullable    = false
  validation {
    # GCP project IDs: 6-30 lowercase alphanumeric characters and hyphens, must start with a letter,
    # cannot end with a hyphen. https://cloud.google.com/resource-manager/docs/creating-managing-projects
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.host_project_id))
    error_message = "host_project_id must be a valid GCP project ID: 6-30 characters, lowercase letters, digits, and hyphens, must start with a letter and not end with a hyphen."
  }
}

variable "service_project_ids" {
  type        = list(string)
  description = "List of GCP project IDs to attach as Shared VPC service projects. At least one service project is required."
  nullable    = false
  validation {
    condition     = length(var.service_project_ids) >= 1
    error_message = "At least one service project ID must be provided in service_project_ids."
  }
  validation {
    # Each entry must be a valid GCP project ID
    condition = alltrue([
      for id in var.service_project_ids :
      can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", id))
    ])
    error_message = "Each service_project_ids entry must be a valid GCP project ID: 6-30 characters, lowercase letters, digits, and hyphens, must start with a letter and not end with a hyphen."
  }
}

variable "subnet_iam_grants" {
  type = list(object({
    subnetwork = string
    region     = string
    member     = string
    role       = string
  }))
  description = "Optional list of IAM bindings to add on specific subnetworks in the host project. Each entry grants a single member a single role on a single subnetwork. Useful for granting service-project service accounts access to Shared VPC subnets (e.g., roles/compute.networkUser). Leave empty to skip subnet-level IAM grants."
  default     = []
  nullable    = false
}
