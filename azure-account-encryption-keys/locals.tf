locals {
  # Resource group for the private endpoint. Falls back to the Key Vault resource group
  # when not overridden in the private_endpoint input.
  pe_resource_group_name = (
    var.private_endpoint != null && var.private_endpoint.resource_group_name != null
    ? var.private_endpoint.resource_group_name
    : var.resource_group_name
  )
}
