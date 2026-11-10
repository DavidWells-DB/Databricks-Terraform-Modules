resource "databricks_mws_network_connectivity_config" "this" {
  provider   = databricks.account
  name       = var.name
  region     = var.region
  account_id = var.databricks_account_id
}

# SINGLE-OWNER CONSOLIDATION (2026-11-10, H5-1): databricks_account_network_policy now has
# exactly one owning module — dbx-account-network-policy (which also carries the E11
# idempotency-correct account_id and the full mode/enforcement/destination surface). The
# allowed_internet_destinations and network_policy_id inputs stay as guarded pointers so
# existing callers fail at PLAN time with the migration path instead of silently creating a
# second policy object behind the NCC.
