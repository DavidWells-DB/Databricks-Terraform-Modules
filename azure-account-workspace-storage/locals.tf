locals {
  # Storage account name: prefix + "stor" suffix. Azure names must be globally unique,
  # lowercase alphanumeric, 3-24 chars. Callers should choose a prefix unique to their
  # environment (e.g. include workspace name or short random suffix in resource_prefix).
  storage_account_name = "${var.resource_prefix}stor"

  # Default container name when not provided.
  container_name = var.container_name != null ? var.container_name : "databricks"

  # Customer-managed key settings. When kms_key_id is null, the block is omitted
  # and Microsoft-managed keys are used.
  use_cmk = var.kms_key_id != null
}
