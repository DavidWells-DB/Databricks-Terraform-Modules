# Enable IP access list enforcement for the workspace.
# Without this workspace_conf setting the databricks_ip_access_list resources
# are created but silently not enforced — the flag is the activation switch.
resource "databricks_workspace_conf" "this" {
  provider = databricks.workspace

  custom_config = {
    enableIpAccessLists = "true"
  }
}

resource "databricks_ip_access_list" "allow" {
  provider = databricks.workspace

  label        = var.allow_list_label
  list_type    = "ALLOW"
  ip_addresses = var.allow_list_cidrs
  enabled      = true

  depends_on = [databricks_workspace_conf.this]
}

# Block list is optional — created only when block_list_cidrs is non-null.
resource "databricks_ip_access_list" "block" {
  count    = var.block_list_cidrs != null ? 1 : 0
  provider = databricks.workspace

  label        = var.block_list_label
  list_type    = "BLOCK"
  ip_addresses = var.block_list_cidrs
  enabled      = true

  depends_on = [databricks_workspace_conf.this]
}
