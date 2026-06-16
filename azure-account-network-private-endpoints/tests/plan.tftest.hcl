mock_provider "azurerm" {}

variables {
  resource_group_name    = "rg-databricks-networking"
  location               = "eastus"
  workspace_resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-databricks/providers/Microsoft.Databricks/workspaces/my-workspace"
  pe_subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-databricks-networking/providers/Microsoft.Network/virtualNetworks/spoke-vnet/subnets/pe-subnet"
  vnet_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-databricks-networking/providers/Microsoft.Network/virtualNetworks/spoke-vnet"
  enable_front_end_pe    = false
  enable_browser_auth_pe = false
}

# --- DNS zone ---

run "dns_zone_name_is_privatelink_azuredatabricks" {
  command = plan

  assert {
    condition     = azurerm_private_dns_zone.this.name == "privatelink.azuredatabricks.net"
    error_message = "DNS zone must always be privatelink.azuredatabricks.net"
  }
}

run "dns_zone_resource_group_matches_input" {
  command = plan

  assert {
    condition     = azurerm_private_dns_zone.this.resource_group_name == "rg-databricks-networking"
    error_message = "DNS zone resource group must match resource_group_name input"
  }
}

# --- Back-end PE always created ---

run "back_end_pe_always_planned" {
  command = plan

  assert {
    condition     = contains(keys(azurerm_private_endpoint.this), "back_end")
    error_message = "back_end private endpoint must always be planned"
  }
}

run "back_end_pe_subresource_is_databricks_ui_api" {
  command = plan

  assert {
    condition     = azurerm_private_endpoint.this["back_end"].private_service_connection[0].subresource_names == tolist(["databricks_ui_api"])
    error_message = "back_end PE must use databricks_ui_api sub-resource"
  }
}

run "back_end_pe_location_matches_input" {
  command = plan

  assert {
    condition     = azurerm_private_endpoint.this["back_end"].location == "eastus"
    error_message = "back_end PE location must match the location input"
  }
}

# --- Front-end PE conditional ---

run "front_end_pe_not_created_by_default" {
  command = plan

  assert {
    condition     = !contains(keys(azurerm_private_endpoint.this), "front_end")
    error_message = "front_end PE must not be created when enable_front_end_pe is false"
  }
}

run "front_end_pe_created_when_enabled" {
  command = plan

  variables {
    enable_front_end_pe = true
  }

  assert {
    condition     = contains(keys(azurerm_private_endpoint.this), "front_end")
    error_message = "front_end PE must be planned when enable_front_end_pe is true"
  }
}

# --- Browser auth PE conditional ---

run "browser_auth_pe_not_created_by_default" {
  command = plan

  assert {
    condition     = !contains(keys(azurerm_private_endpoint.this), "browser_auth")
    error_message = "browser_auth PE must not be created when enable_browser_auth_pe is false"
  }
}

run "browser_auth_pe_created_when_enabled" {
  command = plan

  variables {
    enable_browser_auth_pe = true
  }

  assert {
    condition     = contains(keys(azurerm_private_endpoint.this), "browser_auth")
    error_message = "browser_auth PE must be planned when enable_browser_auth_pe is true"
  }
}

run "browser_auth_pe_subresource_is_browser_authentication" {
  command = plan

  variables {
    enable_browser_auth_pe = true
  }

  assert {
    condition     = azurerm_private_endpoint.this["browser_auth"].private_service_connection[0].subresource_names == tolist(["browser_authentication"])
    error_message = "browser_auth PE must use browser_authentication sub-resource"
  }
}

# --- Spoke VNet link always created ---

run "spoke_vnet_link_always_planned" {
  command = plan

  assert {
    condition     = contains(keys(azurerm_private_dns_zone_virtual_network_link.this), "spoke")
    error_message = "Spoke VNet DNS link must always be planned"
  }
}

run "spoke_vnet_link_vnet_id_matches_input" {
  command = plan

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.this["spoke"].virtual_network_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-databricks-networking/providers/Microsoft.Network/virtualNetworks/spoke-vnet"
    error_message = "Spoke VNet link must use the vnet_id input"
  }
}

run "spoke_vnet_link_registration_disabled" {
  command = plan

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.this["spoke"].registration_enabled == false
    error_message = "DNS zone VNet link registration must be disabled (Databricks manages its own DNS records)"
  }
}

# --- Hub VNet links ---

run "hub_vnet_link_created_when_provided" {
  command = plan

  variables {
    hub_vnet_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/hub-vnet"]
  }

  assert {
    condition     = contains(keys(azurerm_private_dns_zone_virtual_network_link.this), "hub_0")
    error_message = "hub_0 VNet DNS link must be planned when hub_vnet_ids is non-empty"
  }
}

# --- Variable validation ---

run "invalid_resource_group_name_rejected" {
  command = plan

  variables {
    resource_group_name = "invalid.name."
  }

  expect_failures = [var.resource_group_name]
}

run "resource_group_name_too_long_rejected" {
  command = plan

  variables {
    resource_group_name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }

  expect_failures = [var.resource_group_name]
}

run "invalid_location_rejected" {
  command = plan

  variables {
    location = "East US"
  }

  expect_failures = [var.location]
}

run "invalid_workspace_resource_id_rejected" {
  command = plan

  variables {
    workspace_resource_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.workspace_resource_id]
}

run "invalid_pe_subnet_id_rejected" {
  command = plan

  variables {
    pe_subnet_id = "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet"
  }

  expect_failures = [var.pe_subnet_id]
}

run "invalid_vnet_id_rejected" {
  command = plan

  variables {
    vnet_id = "not-a-valid-vnet-id"
  }

  expect_failures = [var.vnet_id]
}

run "invalid_hub_vnet_id_rejected" {
  command = plan

  variables {
    hub_vnet_ids = ["not-a-valid-vnet-id"]
  }

  expect_failures = [var.hub_vnet_ids]
}
