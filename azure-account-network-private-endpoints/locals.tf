locals {
  # Derive a short workspace name from the resource ID for use in resource names.
  # The workspace name is the last segment of the resource ID path.
  workspace_name       = element(split("/", var.workspace_resource_id), length(split("/", var.workspace_resource_id)) - 1)
  back_end_pe_name     = coalesce(var.back_end_pe_name, "${local.workspace_name}-be-pe")
  front_end_pe_name    = coalesce(var.front_end_pe_name, "${local.workspace_name}-fe-pe")
  browser_auth_pe_name = coalesce(var.browser_auth_pe_name, "${local.workspace_name}-browser-auth-pe")
  dns_link_name_prefix = coalesce(var.dns_link_name_prefix, local.workspace_name)

  # All VNets that need a DNS zone link: spoke + any hub VNets.
  all_vnet_links = merge(
    {
      spoke = {
        vnet_id = var.vnet_id
        name    = "${local.dns_link_name_prefix}-spoke-dns-link"
      }
    },
    { for idx, id in var.hub_vnet_ids :
      "hub_${idx}" => {
        vnet_id = id
        name    = "${local.dns_link_name_prefix}-hub-${idx}-dns-link"
      }
    }
  )
}
