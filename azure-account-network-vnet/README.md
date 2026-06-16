# azure-account-network-vnet

Creates the Azure Virtual Network and subnets used for Databricks VNet injection (also called Bring Your Own VNet / BYOVNET on Azure), including the required Network Security Group and subnet-NSG associations.

## What this module abstracts

"The network Databricks uses for VNet injection" — the host subnet, container subnet, shared NSG, and their associations form one indivisible function. You cannot pass partial subnet/NSG configuration to `azurerm_databricks_workspace`; all four pieces must exist and be correctly wired before workspace creation. This module encapsulates that wiring.

Optional: a private endpoint subnet (no delegation, network policies disabled) is created when `pe_subnet_name` and `pe_subnet_cidr` are both provided.

## When to use

- You are provisioning an Azure Databricks workspace with VNet injection (`custom_parameters.virtual_network_id` in `azurerm_databricks_workspace`).
- You want a single module that creates the VNet, subnets, NSG, and associations together.
- You need an optional private endpoint subnet for Databricks Private Link or storage private endpoints.

## When NOT to use

- You already have an existing VNet/subnets managed outside Terraform — pass the subnet IDs and names directly to the workspace module instead.
- You are provisioning a workspace with no VNet injection (Databricks-managed VNet) — in that case no custom VNet is needed.
- You need Azure Firewall or route table configuration — use the `azure-account-network-firewall` module alongside this one.

## Minimum platform tier

**Premium.** Databricks VNet injection is a Premium-tier feature. Applying a workspace with `custom_parameters.virtual_network_id` against a Standard-tier subscription will succeed at the Azure layer but the Databricks workspace creation will fail or produce a non-functional workspace. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Azure Government

Azure Government is parameterized at the `azurerm` provider level via `environment = "usgovernment"` in the root composition. This module has no provider-level Azure Government logic — the `azurerm` provider transparently targets the correct Azure Government endpoints when the root composition configures it.

## Provider configuration

This module uses only the `azurerm` provider. No Databricks provider is required — Azure's VNet injection wires through `azurerm_databricks_workspace` `custom_parameters`, not through `databricks_mws_networks`. The caller must supply an `azurerm` provider configured for the target Azure subscription and region.

## NSG rule lifecycle

The Databricks control plane injects NSG rules into the shared NSG after workspace creation via the Azure Databricks resource provider. This module sets `lifecycle { ignore_changes = [security_rule] }` on the NSG to prevent Terraform from reverting those control-plane-managed rules on subsequent plans (per DATABRICKS_RULES.md Rule 3.2).

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.75 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.75 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_subnet.container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.host](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.pe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.host](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_container_subnet_cidr"></a> [container\_subnet\_cidr](#input\_container\_subnet\_cidr) | CIDR block for the Databricks container subnet (e.g. "10.0.2.0/24"). Must be a subset of vnet\_cidr and at least /26. | `string` | n/a | yes |
| <a name="input_container_subnet_name"></a> [container\_subnet\_name](#input\_container\_subnet\_name) | Name for the Databricks container subnet. | `string` | n/a | yes |
| <a name="input_host_subnet_cidr"></a> [host\_subnet\_cidr](#input\_host\_subnet\_cidr) | CIDR block for the Databricks host subnet (e.g. "10.0.1.0/24"). Must be a subset of vnet\_cidr and at least /26. | `string` | n/a | yes |
| <a name="input_host_subnet_name"></a> [host\_subnet\_name](#input\_host\_subnet\_name) | Name for the Databricks host (compute) subnet. Must not be "AzureBastionSubnet" or "GatewaySubnet" — those are reserved Azure names. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region where the VNet and subnets are created (e.g. "eastus", "westeurope"). Must match the resource group's region. | `string` | n/a | yes |
| <a name="input_nsg_name"></a> [nsg\_name](#input\_nsg\_name) | Name for the Network Security Group applied to both Databricks subnets. A single NSG is shared between host and container subnets as required by Databricks VNet injection. | `string` | n/a | yes |
| <a name="input_pe_subnet_cidr"></a> [pe\_subnet\_cidr](#input\_pe\_subnet\_cidr) | CIDR block for the optional private endpoint subnet (e.g. "10.0.3.0/27"). Required when pe\_subnet\_name is set; ignored when pe\_subnet\_name is null. | `string` | `null` | no |
| <a name="input_pe_subnet_name"></a> [pe\_subnet\_name](#input\_pe\_subnet\_name) | Name for the optional private endpoint subnet. Set to null to skip private endpoint subnet creation. | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the Azure resource group in which to create the VNet and subnets. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all Azure resources created by this module. | `map(string)` | `{}` | no |
| <a name="input_vnet_cidr"></a> [vnet\_cidr](#input\_vnet\_cidr) | CIDR block for the Virtual Network address space (e.g. "10.0.0.0/16"). Must be large enough to accommodate the host, container, and optional PE subnets. | `string` | n/a | yes |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | Name for the Azure Virtual Network. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_container_subnet_id"></a> [container\_subnet\_id](#output\_container\_subnet\_id) | Resource ID of the Databricks container subnet. Pass to the workspace creation module's custom\_parameters as the private\_subnet\_network\_security\_group\_association\_id. |
| <a name="output_container_subnet_name"></a> [container\_subnet\_name](#output\_container\_subnet\_name) | Name of the Databricks container subnet. Required by azurerm\_databricks\_workspace custom\_parameters. |
| <a name="output_host_subnet_id"></a> [host\_subnet\_id](#output\_host\_subnet\_id) | Resource ID of the Databricks host subnet. Pass to the workspace creation module's custom\_parameters as the virtual\_network\_subnet\_id. |
| <a name="output_host_subnet_name"></a> [host\_subnet\_name](#output\_host\_subnet\_name) | Name of the Databricks host subnet. Required by azurerm\_databricks\_workspace custom\_parameters. |
| <a name="output_nsg_id"></a> [nsg\_id](#output\_nsg\_id) | Resource ID of the Network Security Group associated with the Databricks subnets. Useful for additional rule management or cross-referencing. |
| <a name="output_nsg_name"></a> [nsg\_name](#output\_nsg\_name) | Name of the Network Security Group associated with the Databricks subnets. |
| <a name="output_pe_subnet_id"></a> [pe\_subnet\_id](#output\_pe\_subnet\_id) | Resource ID of the optional private endpoint subnet. Null when pe\_subnet\_name is not set. |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | Resource ID of the Azure Virtual Network. Pass to workspace creation modules and private endpoint modules as the vnet\_id input. |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | Name of the Azure Virtual Network. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid minimal configuration plans successfully with expected resource attributes.
- Optional PE subnet is created when both `pe_subnet_name` and `pe_subnet_cidr` are provided.
- Optional PE subnet is skipped when `pe_subnet_name` is null.
- All variable validations (invalid CIDR, bad names, empty strings) are rejected at plan time.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Azure subscription) verifies actual VNet and subnet creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
