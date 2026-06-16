mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-hub-databricks"
  location            = "eastus"
  firewall_name       = "hub-fw"
  firewall_subnet_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/hub-vnet/subnets/AzureFirewallSubnet"
  spoke_subnet_ids = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-spoke/providers/Microsoft.Network/virtualNetworks/spoke-vnet/subnets/host-subnet",
  ]
  allowed_spoke_cidr_ranges = ["10.1.0.0/24"]
  service_tag_rules = [
    {
      name              = "allow-databricks"
      priority          = 100
      action            = "Allow"
      destination_tags  = ["AzureDatabricks"]
      destination_ports = ["443"]
      protocols         = ["TCP"]
    },
  ]
}

# ── Variable validation ────────────────────────────────────────────────────────

run "resource_group_name_empty_rejected" {
  command = plan

  variables {
    resource_group_name = ""
  }

  expect_failures = [var.resource_group_name]
}

run "resource_group_name_ends_with_period_rejected" {
  command = plan

  variables {
    resource_group_name = "rg-hub."
  }

  expect_failures = [var.resource_group_name]
}

run "location_empty_rejected" {
  command = plan

  variables {
    location = "   "
  }

  expect_failures = [var.location]
}

run "firewall_name_too_long_rejected" {
  command = plan

  variables {
    firewall_name = "this-firewall-name-is-way-too-long-and-exceeds-the-azure-fifty-six-char-limit-abc"
  }

  expect_failures = [var.firewall_name]
}

run "firewall_name_empty_rejected" {
  command = plan

  variables {
    firewall_name = ""
  }

  expect_failures = [var.firewall_name]
}

run "firewall_subnet_id_invalid_format_rejected" {
  command = plan

  variables {
    firewall_subnet_id = "not-a-subnet-id"
  }

  expect_failures = [var.firewall_subnet_id]
}

run "spoke_subnet_ids_empty_rejected" {
  command = plan

  variables {
    spoke_subnet_ids = []
  }

  expect_failures = [var.spoke_subnet_ids]
}

run "spoke_subnet_id_invalid_format_rejected" {
  command = plan

  variables {
    spoke_subnet_ids = ["not-a-resource-id"]
  }

  expect_failures = [var.spoke_subnet_ids]
}

run "allowed_spoke_cidr_ranges_empty_rejected" {
  command = plan

  variables {
    allowed_spoke_cidr_ranges = []
  }

  expect_failures = [var.allowed_spoke_cidr_ranges]
}

run "allowed_spoke_cidr_ranges_invalid_cidr_rejected" {
  command = plan

  variables {
    allowed_spoke_cidr_ranges = ["not-a-cidr"]
  }

  expect_failures = [var.allowed_spoke_cidr_ranges]
}

run "service_tag_rules_empty_rejected" {
  command = plan

  variables {
    service_tag_rules = []
  }

  expect_failures = [var.service_tag_rules]
}

run "service_tag_rules_priority_too_low_rejected" {
  command = plan

  variables {
    service_tag_rules = [
      {
        name              = "bad-priority"
        priority          = 50
        action            = "Allow"
        destination_tags  = ["AzureDatabricks"]
        destination_ports = ["443"]
        protocols         = ["TCP"]
      },
    ]
  }

  expect_failures = [var.service_tag_rules]
}

run "service_tag_rules_priority_too_high_rejected" {
  command = plan

  variables {
    service_tag_rules = [
      {
        name              = "bad-priority-high"
        priority          = 65001
        action            = "Allow"
        destination_tags  = ["AzureDatabricks"]
        destination_ports = ["443"]
        protocols         = ["TCP"]
      },
    ]
  }

  expect_failures = [var.service_tag_rules]
}

run "service_tag_rules_invalid_action_rejected" {
  command = plan

  variables {
    service_tag_rules = [
      {
        name              = "bad-action"
        priority          = 100
        action            = "Permit"
        destination_tags  = ["AzureDatabricks"]
        destination_ports = ["443"]
        protocols         = ["TCP"]
      },
    ]
  }

  expect_failures = [var.service_tag_rules]
}

run "service_tag_rules_invalid_protocol_rejected" {
  command = plan

  variables {
    service_tag_rules = [
      {
        name              = "bad-protocol"
        priority          = 100
        action            = "Allow"
        destination_tags  = ["AzureDatabricks"]
        destination_ports = ["443"]
        protocols         = ["HTTP"]
      },
    ]
  }

  expect_failures = [var.service_tag_rules]
}

run "firewall_sku_tier_invalid_rejected" {
  command = plan

  variables {
    firewall_sku_tier = "Basic"
  }

  expect_failures = [var.firewall_sku_tier]
}

# ── Resource attribute checks ──────────────────────────────────────────────────

run "firewall_uses_input_name" {
  command = plan

  assert {
    condition     = azurerm_firewall.this.name == "hub-fw"
    error_message = "Firewall name should match the firewall_name input"
  }
}

run "firewall_policy_named_with_suffix" {
  command = plan

  assert {
    condition     = azurerm_firewall_policy.this.name == "hub-fw-policy"
    error_message = "Firewall policy name should be <firewall_name>-policy"
  }
}

run "ip_group_named_with_suffix" {
  command = plan

  assert {
    condition     = azurerm_ip_group.this.name == "hub-fw-spoke-ips"
    error_message = "IP group name should be <firewall_name>-spoke-ips"
  }
}

run "route_table_named_with_suffix" {
  command = plan

  assert {
    condition     = azurerm_route_table.this.name == "hub-fw-spoke-rt"
    error_message = "Route table name should be <firewall_name>-spoke-rt"
  }
}

run "route_table_bgp_propagation_disabled" {
  command = plan

  assert {
    condition     = azurerm_route_table.this.bgp_route_propagation_enabled == false
    error_message = "BGP route propagation must be disabled on the spoke route table to prevent gateway routes from bypassing the firewall"
  }
}

run "forced_tunnel_route_next_hop_is_virtual_appliance" {
  command = plan

  assert {
    condition     = azurerm_route.this.next_hop_type == "VirtualAppliance"
    error_message = "Forced-tunnel route next_hop_type must be VirtualAppliance"
  }
}

run "forced_tunnel_route_destination_is_default_route" {
  command = plan

  assert {
    condition     = azurerm_route.this.address_prefix == "0.0.0.0/0"
    error_message = "Forced-tunnel route address_prefix must be 0.0.0.0/0"
  }
}

run "firewall_sku_tier_default_is_premium" {
  command = plan

  assert {
    condition     = azurerm_firewall.this.sku_tier == "Premium"
    error_message = "Default firewall_sku_tier should be Premium"
  }
}

run "standard_sku_tier_accepted" {
  command = plan

  variables {
    firewall_sku_tier = "Standard"
  }

  assert {
    condition     = azurerm_firewall.this.sku_tier == "Standard"
    error_message = "Standard firewall_sku_tier should be accepted and applied to the firewall resource"
  }
}

run "firewall_policy_and_firewall_share_same_sku" {
  command = plan

  variables {
    firewall_sku_tier = "Standard"
  }

  assert {
    condition     = azurerm_firewall_policy.this.sku == "Standard" && azurerm_firewall.this.sku_tier == "Standard"
    error_message = "Firewall and firewall policy must share the same SKU tier"
  }
}

run "ip_group_cidrs_match_input" {
  command = plan

  assert {
    condition     = toset(azurerm_ip_group.this.cidrs) == toset(["10.1.0.0/24"])
    error_message = "IP group CIDRs should match the allowed_spoke_cidr_ranges input"
  }
}

run "public_ip_is_standard_sku" {
  command = plan

  assert {
    condition     = azurerm_public_ip.this.sku == "Standard"
    error_message = "Public IP must use Standard SKU for Azure Firewall compatibility"
  }
}

run "public_ip_is_static_allocation" {
  command = plan

  assert {
    condition     = azurerm_public_ip.this.allocation_method == "Static"
    error_message = "Public IP must use Static allocation for Azure Firewall"
  }
}
