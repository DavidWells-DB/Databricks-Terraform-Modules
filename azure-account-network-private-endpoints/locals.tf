locals {
  # Derive a short workspace name from the resource ID for use in resource names.
  # The workspace name is the last segment of the resource ID path.
  workspace_name = element(split("/", var.workspace_resource_id), length(split("/", var.workspace_resource_id)) - 1)

  # Map of all private endpoints to create.
  # back_end is always created; front_end and browser_auth are conditional.
  private_endpoints = merge(
    {
      back_end = {
        name              = "${local.workspace_name}-be-pe"
        subresource_names = ["databricks_ui_api"]
      }
    },
    var.enable_front_end_pe ? {
      front_end = {
        name              = "${local.workspace_name}-fe-pe"
        subresource_names = ["databricks_ui_api"]
      }
    } : {},
    var.enable_browser_auth_pe ? {
      browser_auth = {
        name              = "${local.workspace_name}-browser-auth-pe"
        subresource_names = ["browser_authentication"]
      }
    } : {}
  )

  # All VNets that need a DNS zone link: spoke + any hub VNets.
  all_vnet_links = merge(
    {
      spoke = {
        vnet_id = var.vnet_id
        name    = "${local.workspace_name}-spoke-dns-link"
      }
    },
    { for idx, id in var.hub_vnet_ids :
      "hub_${idx}" => {
        vnet_id = id
        name    = "${local.workspace_name}-hub-${idx}-dns-link"
      }
    }
  )
}
