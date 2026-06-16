locals {
  # Root DBFS CMK post-creation resource is created only when a key is supplied.
  root_dbfs_cmk_enabled = var.root_dbfs_cmk_key_vault_key_id != null
}
