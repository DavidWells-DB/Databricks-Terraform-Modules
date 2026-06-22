variable "metastore_name" {
  type        = string
  description = "Display name for the Unity Catalog metastore. Must be unique within the Databricks account."
  nullable    = false
  validation {
    # No Databricks-published character constraint; using conservative common-sense bounds.
    # 1-255 chars, no leading/trailing whitespace.
    condition     = length(trimspace(var.metastore_name)) >= 1 && length(var.metastore_name) <= 255 && var.metastore_name == trimspace(var.metastore_name)
    error_message = "metastore_name must be 1-255 characters and must not have leading or trailing whitespace."
  }
}

variable "region" {
  type        = string
  description = "Cloud region where the metastore is created. Must match the region of any workspaces you intend to assign. One metastore per account per region."
  nullable    = false
  validation {
    # Region must be a non-empty alphanumeric/hyphen string (e.g., "us-east-1", "eastus", "us-central1").
    condition     = length(trimspace(var.region)) >= 1 && can(regex("^[A-Za-z0-9-]+$", var.region))
    error_message = "region must be a non-empty alphanumeric/hyphen string (e.g., \"us-east-1\", \"eastus\", \"us-central1\")."
  }
}

variable "storage_root_url" {
  type        = string
  description = "Optional cloud storage URL for the metastore root. Leave null/unset for a storageless metastore (recommended; manage storage at the catalog level instead). On AWS: s3://bucket-name/optional-prefix. On Azure: abfss://container@account.dfs.core.windows.net/optional-prefix. On GCP: gs://bucket-name/optional-prefix."
  default     = null
  nullable    = true
  validation {
    # When set, must start with one of the supported cloud storage schemes.
    condition     = var.storage_root_url == null || can(regex("^(s3|abfss|gs)://", var.storage_root_url))
    error_message = "storage_root_url must be null or begin with s3://, abfss://, or gs://."
  }
}

variable "data_access_name" {
  type        = string
  description = "Name for the default data access configuration (databricks_metastore_data_access). Required when storage_credential is set; leave null for a storageless metastore."
  default     = null
  nullable    = true
  validation {
    condition     = var.data_access_name == null || (length(trimspace(var.data_access_name)) >= 1 && length(var.data_access_name) <= 255 && var.data_access_name == trimspace(var.data_access_name))
    error_message = "data_access_name must be null or 1-255 characters with no leading or trailing whitespace."
  }
}

variable "storage_credential" {
  type = object({
    aws_iam_role = optional(object({
      role_arn = string
    }))
    azure_managed_identity = optional(object({
      access_connector_id = string
      managed_identity_id = optional(string)
    }))
    databricks_gcp_service_account = optional(object({}))
  })
  description = "Optional storage credential for the metastore default data access. Leave null for a storageless metastore. When set, populate exactly one cloud-specific block: aws_iam_role for AWS, azure_managed_identity for Azure, or databricks_gcp_service_account for GCP. Per DATABRICKS_RULES.md Rule 2.4."
  default     = null
  nullable    = true
  validation {
    condition = var.storage_credential == null || (
      (var.storage_credential.aws_iam_role != null ? 1 : 0) +
      (var.storage_credential.azure_managed_identity != null ? 1 : 0) +
      (var.storage_credential.databricks_gcp_service_account != null ? 1 : 0)
    ) == 1
    error_message = "When set, exactly one of storage_credential.aws_iam_role, storage_credential.azure_managed_identity, or storage_credential.databricks_gcp_service_account must be specified."
  }
}

variable "owner_group" {
  type        = string
  description = "Databricks account-level group that owns the metastore. Defaults to the creating principal if not set."
  default     = null
  nullable    = true
  validation {
    condition     = var.owner_group == null || (length(trimspace(var.owner_group)) >= 1 && var.owner_group == trimspace(var.owner_group))
    error_message = "owner_group must be null or a non-empty string with no leading/trailing whitespace."
  }
}
