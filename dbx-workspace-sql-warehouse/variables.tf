variable "name" {
  type        = string
  description = "Name of the SQL warehouse. Must be unique within the workspace."
  nullable    = false
  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 255
    error_message = "name must be between 1 and 255 characters."
  }
}

variable "cluster_size" {
  type        = string
  description = "Size of the warehouse cluster. Valid values: 2X-Small, X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large."
  nullable    = false
  validation {
    condition = contains([
      "2X-Small", "X-Small", "Small", "Medium", "Large",
      "X-Large", "2X-Large", "3X-Large", "4X-Large"
    ], var.cluster_size)
    error_message = "cluster_size must be one of: 2X-Small, X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large."
  }
}

variable "warehouse_type" {
  type        = string
  description = "Type of the warehouse. Valid values: CLASSIC, PRO."
  default     = "PRO"
  validation {
    condition     = contains(["CLASSIC", "PRO"], var.warehouse_type)
    error_message = "warehouse_type must be one of: CLASSIC, PRO."
  }
}

variable "auto_stop_mins" {
  type        = number
  description = "Time in minutes after which the warehouse will stop automatically if idle. Set to 0 to disable auto-stop."
  default     = 10
  validation {
    condition     = var.auto_stop_mins >= 0
    error_message = "auto_stop_mins must be >= 0."
  }
}

variable "min_num_clusters" {
  type        = number
  description = "Minimum number of warehouse clusters. Must be >= 1."
  default     = 1
  validation {
    condition     = var.min_num_clusters >= 1
    error_message = "min_num_clusters must be >= 1."
  }
}

variable "max_num_clusters" {
  type        = number
  description = "Maximum number of warehouse clusters for auto-scaling. Must be >= min_num_clusters."
  default     = 1
  validation {
    condition     = var.max_num_clusters >= 1
    error_message = "max_num_clusters must be >= 1."
  }
}

variable "spot_instance_policy" {
  type        = string
  description = "Spot instance policy for cost optimization. Valid values: COST_OPTIMIZED, RELIABILITY_OPTIMIZED, POLICY_UNSPECIFIED."
  default     = "COST_OPTIMIZED"
  validation {
    condition     = contains(["COST_OPTIMIZED", "RELIABILITY_OPTIMIZED", "POLICY_UNSPECIFIED"], var.spot_instance_policy)
    error_message = "spot_instance_policy must be one of: COST_OPTIMIZED, RELIABILITY_OPTIMIZED, POLICY_UNSPECIFIED."
  }
}

variable "channel" {
  type        = string
  description = "Warehouse release channel. CURRENT for stable releases, PREVIEW for preview features. Valid values: CURRENT, PREVIEW."
  default     = "CURRENT"
  validation {
    condition     = contains(["CURRENT", "PREVIEW"], var.channel)
    error_message = "channel must be one of: CURRENT, PREVIEW."
  }
}

variable "enable_photon" {
  type        = bool
  description = "Enable Photon acceleration. Requires Premium tier or higher."
  default     = true
}

variable "enable_serverless_compute" {
  type        = bool
  description = "Enable serverless compute for the warehouse. When true, warehouse uses serverless infrastructure."
  default     = false
}

variable "permissions" {
  type        = map(string)
  description = "Map of principal (user email, group name, or service principal application ID) to permission level. Valid permission levels: CAN_USE, CAN_MANAGE, CAN_MONITOR, IS_OWNER."
  default     = {}
  validation {
    condition = alltrue([
      for principal, level in var.permissions :
      contains(["CAN_USE", "CAN_MANAGE", "CAN_MONITOR", "IS_OWNER"], level)
    ])
    error_message = "All permission levels must be one of: CAN_USE, CAN_MANAGE, CAN_MONITOR, IS_OWNER."
  }
}

variable "tags" {
  type        = map(string)
  description = "Custom tags to apply to the warehouse."
  default     = {}
}
