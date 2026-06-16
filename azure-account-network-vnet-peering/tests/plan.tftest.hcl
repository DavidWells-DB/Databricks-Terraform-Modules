mock_provider "azurerm" {}

variables {
  local_vnet_name            = "spoke-vnet"
  remote_vnet_name           = "hub-vnet"
  local_vnet_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/spoke-rg/providers/Microsoft.Network/virtualNetworks/spoke-vnet"
  remote_vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub-vnet"
  local_resource_group_name  = "spoke-rg"
  remote_resource_group_name = "hub-rg"
}

run "local_to_remote_peering_named_correctly" {
  command = plan

  assert {
    condition     = azurerm_virtual_network_peering.local_to_remote.name == "spoke-vnet-to-hub-vnet"
    error_message = "Local-to-remote peering name should be <local_vnet_name>-to-<remote_vnet_name>"
  }
}

run "remote_to_local_peering_named_correctly" {
  command = plan

  assert {
    condition     = azurerm_virtual_network_peering.remote_to_local.name == "hub-vnet-to-spoke-vnet"
    error_message = "Remote-to-local peering name should be <remote_vnet_name>-to-<local_vnet_name>"
  }
}

run "local_peering_targets_remote_vnet" {
  command = plan

  assert {
    condition     = azurerm_virtual_network_peering.local_to_remote.remote_virtual_network_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub-vnet"
    error_message = "Local-to-remote peering should target the remote VNet ID"
  }
}

run "remote_peering_targets_local_vnet" {
  command = plan

  assert {
    condition     = azurerm_virtual_network_peering.remote_to_local.remote_virtual_network_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/spoke-rg/providers/Microsoft.Network/virtualNetworks/spoke-vnet"
    error_message = "Remote-to-local peering should target the local VNet ID"
  }
}

run "invalid_local_vnet_name_rejected" {
  command = plan

  variables {
    local_vnet_name = "a"
  }

  expect_failures = [var.local_vnet_name]
}

run "invalid_remote_vnet_name_rejected" {
  command = plan

  variables {
    remote_vnet_name = "name with spaces!"
  }

  expect_failures = [var.remote_vnet_name]
}

run "invalid_local_vnet_id_rejected" {
  command = plan

  variables {
    local_vnet_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.local_vnet_id]
}

run "invalid_remote_vnet_id_rejected" {
  command = plan

  variables {
    remote_vnet_id = "/subscriptions/abc/only-partially-valid"
  }

  expect_failures = [var.remote_vnet_id]
}

run "invalid_local_resource_group_name_rejected" {
  command = plan

  variables {
    local_resource_group_name = "rg name with spaces"
  }

  expect_failures = [var.local_resource_group_name]
}

run "invalid_remote_resource_group_name_rejected" {
  command = plan

  variables {
    remote_resource_group_name = "rg/name/with/slashes"
  }

  expect_failures = [var.remote_resource_group_name]
}

run "gateway_transit_and_use_remote_gateways_mutually_exclusive" {
  command = plan

  variables {
    allow_gateway_transit = true
    use_remote_gateways   = true
  }

  expect_failures = [var.use_remote_gateways]
}

run "gateway_settings_reversed_on_return_leg" {
  command = plan

  variables {
    allow_gateway_transit = true
    use_remote_gateways   = false
  }

  assert {
    condition     = azurerm_virtual_network_peering.local_to_remote.allow_gateway_transit == true
    error_message = "Local-to-remote peering should have allow_gateway_transit = true when input is true"
  }

  assert {
    condition     = azurerm_virtual_network_peering.remote_to_local.use_remote_gateways == true
    error_message = "Remote-to-local peering should have use_remote_gateways = true when allow_gateway_transit = true on local side"
  }
}
