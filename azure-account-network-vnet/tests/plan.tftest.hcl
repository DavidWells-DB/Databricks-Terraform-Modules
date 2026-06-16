mock_provider "azurerm" {}

variables {
  resource_group_name   = "rg-databricks-test"
  location              = "eastus"
  vnet_name             = "databricks-vnet"
  vnet_cidr             = "10.0.0.0/16"
  host_subnet_name      = "databricks-host"
  host_subnet_cidr      = "10.0.1.0/24"
  container_subnet_name = "databricks-container"
  container_subnet_cidr = "10.0.2.0/24"
  nsg_name              = "databricks-nsg"
  pe_subnet_name        = null
  pe_subnet_cidr        = null
}

run "vnet_planned_with_expected_name" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.this.name == "databricks-vnet"
    error_message = "VNet name should match vnet_name input"
  }
}

run "vnet_planned_with_expected_cidr" {
  command = plan

  assert {
    condition     = contains(azurerm_virtual_network.this.address_space, "10.0.0.0/16")
    error_message = "VNet address space should contain the vnet_cidr input"
  }
}

run "host_subnet_planned_with_expected_name" {
  command = plan

  assert {
    condition     = azurerm_subnet.host.name == "databricks-host"
    error_message = "Host subnet name should match host_subnet_name input"
  }
}

run "container_subnet_planned_with_expected_name" {
  command = plan

  assert {
    condition     = azurerm_subnet.container.name == "databricks-container"
    error_message = "Container subnet name should match container_subnet_name input"
  }
}

run "nsg_planned_with_expected_name" {
  command = plan

  assert {
    condition     = azurerm_network_security_group.this.name == "databricks-nsg"
    error_message = "NSG name should match nsg_name input"
  }
}

run "pe_subnet_not_created_when_null" {
  command = plan

  assert {
    condition     = length(azurerm_subnet.pe) == 0
    error_message = "PE subnet should not be created when pe_subnet_name and pe_subnet_cidr are null"
  }
}

run "pe_subnet_created_when_provided" {
  command = plan

  variables {
    pe_subnet_name = "databricks-pe"
    pe_subnet_cidr = "10.0.3.0/27"
  }

  assert {
    condition     = length(azurerm_subnet.pe) == 1
    error_message = "PE subnet should be created when pe_subnet_name and pe_subnet_cidr are both provided"
  }
}

run "pe_subnet_name_matches_input" {
  command = plan

  variables {
    pe_subnet_name = "databricks-pe"
    pe_subnet_cidr = "10.0.3.0/27"
  }

  assert {
    condition     = azurerm_subnet.pe[0].name == "databricks-pe"
    error_message = "PE subnet name should match pe_subnet_name input"
  }
}

run "invalid_vnet_cidr_rejected" {
  command = plan

  variables {
    vnet_cidr = "not-a-cidr"
  }

  expect_failures = [var.vnet_cidr]
}

run "invalid_host_subnet_cidr_rejected" {
  command = plan

  variables {
    host_subnet_cidr = "256.0.0.0/24"
  }

  expect_failures = [var.host_subnet_cidr]
}

run "invalid_container_subnet_cidr_rejected" {
  command = plan

  variables {
    container_subnet_cidr = "bad-cidr"
  }

  expect_failures = [var.container_subnet_cidr]
}

run "invalid_pe_subnet_cidr_rejected" {
  command = plan

  variables {
    pe_subnet_name = "pe"
    pe_subnet_cidr = "not-a-cidr"
  }

  expect_failures = [var.pe_subnet_cidr]
}

run "empty_location_rejected" {
  command = plan

  variables {
    location = "   "
  }

  expect_failures = [var.location]
}

run "vnet_name_too_short_rejected" {
  command = plan

  variables {
    vnet_name = "x"
  }

  expect_failures = [var.vnet_name]
}

run "nsg_name_invalid_chars_rejected" {
  command = plan

  variables {
    nsg_name = "invalid name with spaces"
  }

  expect_failures = [var.nsg_name]
}

run "resource_group_name_too_long_rejected" {
  command = plan

  variables {
    resource_group_name = "this-resource-group-name-is-extremely-long-and-definitely-exceeds-the-azure-ninety-character-maximum-limit"
  }

  expect_failures = [var.resource_group_name]
}

run "pe_subnet_name_invalid_chars_rejected" {
  command = plan

  variables {
    pe_subnet_name = "invalid name"
    pe_subnet_cidr = "10.0.3.0/27"
  }

  expect_failures = [var.pe_subnet_name]
}
