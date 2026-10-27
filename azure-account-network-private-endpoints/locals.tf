locals {
  # Derive a short workspace name from the resource ID for use in resource names.
  # The workspace name is the last segment of the resource ID path.
  workspace_name = element(split("/", var.workspace_resource_id), length(split("/", var.workspace_resource_id)) - 1)

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
