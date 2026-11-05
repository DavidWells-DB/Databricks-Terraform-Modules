mock_provider "azurerm" {
  mock_resource "azurerm_nat_gateway" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-databricks-test/providers/Microsoft.Network/natGateways/databricks-nat"
    }
  }

  mock_resource "azurerm_public_ip" {
    defaults = {
      id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-databricks-test/providers/Microsoft.Network/publicIPAddresses/databricks-nat-ip"
      ip_address = "20.1.2.3"
    }
  }

  mock_resource "azurerm_nat_gateway_public_ip_association" {
    defaults = {
      id = "assoc-nat-ip"
    }
  }

  mock_resource "azurerm_subnet_nat_gateway_association" {
    defaults = {
      id = "assoc-subnet"
    }
  }
}

variables {
  resource_group_name = "rg-databricks-test"
  location            = "eastus"
  nat_gateway_name    = "databricks-nat"
  public_ip_name      = "databricks-nat-ip"
  subnets = {
    host      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-databricks-test/providers/Microsoft.Network/virtualNetworks/databricks-vnet/subnets/databricks-host"
    container = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-databricks-test/providers/Microsoft.Network/virtualNetworks/databricks-vnet/subnets/databricks-container"
  }
}

run "nat_gateway_planned_with_expected_name" {
  command = plan

  assert {
    condition     = azurerm_nat_gateway.this.name == "databricks-nat" && azurerm_nat_gateway.this.sku_name == "Standard"
    error_message = "NAT gateway should use the nat_gateway_name input and Standard SKU"
  }
}

run "public_ip_is_standard_static" {
  command = plan

  assert {
    condition     = azurerm_public_ip.this.sku == "Standard" && azurerm_public_ip.this.allocation_method == "Static"
    error_message = "The public IP must be Static + Standard — the NAT gateway association rejects other SKUs"
  }
}

run "associations_use_the_caller_subnet_ids" {
  command = plan

  # Computed resource IDs (nat_gateway_id/public_ip_address_id) are plan-unknown
  # under mocks — assert on the config-typed subnet_id values instead; the NAT↔IP
  # association's existence is proven by the resource graph itself.
  assert {
    condition     = alltrue([for name, assoc in azurerm_subnet_nat_gateway_association.this : assoc.subnet_id == var.subnets[name]])
    error_message = "Every subnet association must carry exactly the caller-supplied subnet ID"
  }
}

run "one_association_per_subnet" {
  command = plan

  assert {
    condition     = length(azurerm_subnet_nat_gateway_association.this) == 2 && contains(keys(azurerm_subnet_nat_gateway_association.this), "host") && contains(keys(azurerm_subnet_nat_gateway_association.this), "container")
    error_message = "Exactly one subnet association per entry of the subnets map, keyed by the caller-chosen names"
  }
}

# (nat_gateway_id on the associations is computed — plan-unknown under mocks; the
# for_each wiring is covered by the subnet-ids run above and the resource graph.)

run "outputs_exposed" {
  command = plan

  # Computed IDs are plan-unknown under mocks; assert the config-typed output.
  assert {
    condition     = output.nat_gateway_name == "databricks-nat"
    error_message = "nat_gateway_name output should match the input"
  }
}

# --- Variable validations ------------------------------------------------------

run "empty_subnets_rejected" {
  command = plan

  variables {
    subnets = {}
  }

  expect_failures = [var.subnets]
}

run "non_subnet_id_rejected" {
  command = plan

  variables {
    subnets = {
      bad = "not-a-subnet-id"
    }
  }

  expect_failures = [var.subnets]
}

run "invalid_nat_gateway_name_rejected" {
  command = plan

  variables {
    nat_gateway_name = "-bad-name"
  }

  expect_failures = [var.nat_gateway_name]
}

run "invalid_resource_group_name_rejected" {
  command = plan

  variables {
    resource_group_name = "invalid."
  }

  expect_failures = [var.resource_group_name]
}
