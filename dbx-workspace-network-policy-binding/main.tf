# Bind an account serverless network policy to a workspace.
#
# A standalone databricks_account_network_policy has no effect until it is BOUND to a
# workspace via databricks_workspace_network_option — the policy alone is a dangling
# no-op. This module is that binding, and nothing else: it does not create the policy
# (see dbx-account-network-policy) and does not require an NCC (see
# dbx-workspace-network-serverless, which couples the binding to an NCC).
#
# databricks_workspace_network_option is an ACCOUNT-surface resource ("can only be used
# with an account-level provider" — provider docs). Binding it via a workspace provider
# fails at apply with "Not Found" (this was open-item E8), so the module declares only
# databricks.account.

# Destroy-ordering guard (open-item E12). Tearing down the binding and the upstream
# policy together races: the policy delete fires before the control plane has finished
# propagating the unbind, failing with "failed to delete account_network_policy" (it
# only succeeded on retry). To insert a settle delay between the binding destroy and the
# policy destroy, we exploit Terraform's reverse-order teardown:
#   - this time_sleep triggers on network_policy_id, so it depends on the (external) policy;
#   - the binding depends_on this time_sleep.
# Create order: policy -> time_sleep -> binding. Destroy order (reversed):
#   binding -> time_sleep (waits destroy_duration) -> policy.
# The delay therefore lands exactly between the unbind and the policy delete. There is no
# create delay — the binding takes effect immediately.
resource "time_sleep" "unbind_settle" {
  triggers = {
    network_policy_id = var.network_policy_id
  }
  destroy_duration = var.unbind_settle_duration
}

resource "databricks_workspace_network_option" "this" {
  provider = databricks.account

  workspace_id      = var.workspace_id
  network_policy_id = var.network_policy_id

  depends_on = [time_sleep.unbind_settle]
}
