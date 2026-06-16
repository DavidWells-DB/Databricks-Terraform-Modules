# azure-account-network-vnet-peering

Creates bidirectional Azure VNet peering between two virtual networks — one peering object in each direction. Both directions are required for connectivity to be established; this module provisions them as an atomic pair.

## What this module abstracts

"The network connectivity between two Azure VNets" — one indivisible function. A single `azurerm_virtual_network_peering` in one direction is inert without the return leg; this module expresses the complete bidirectional peering relationship as one unit.

Typical Databricks use case: peering a Databricks-injected spoke VNet to a hub VNet that provides egress, DNS, or shared services (firewall, NVA, on-premises connectivity via ExpressRoute/VPN gateway).

## When to use

- You need bidirectional VNet peering between a Databricks spoke VNet and a hub/transit VNet.
- You want a single module invocation that atomically manages both peering legs.
- The VNets are in the same Azure subscription or accessible subscriptions (both resource groups must be reachable by the provider's credentials).

## When NOT to use

- You need to peer VNets across different Azure tenants — cross-tenant peering requires additional Azure AD configuration outside this module's scope.
- One peering leg is managed by a separate team — manage the two `azurerm_virtual_network_peering` resources independently at the root composition instead.
- You only need a one-directional peering (unusual; connectivity requires both directions).

## Minimum platform tier

**Premium.** VNet peering is a network prerequisite for VNet-injected Databricks workspaces. VNet injection is a Premium-tier feature. See DATABRICKS_RULES.md Rule 2.3.

## Azure Government

Azure Government is parameterized via the `azurerm` provider `environment = "usgovernment"` at the root composition. This module contains no Azure Government-specific logic; configure the `azurerm` provider appropriately in the root composition before calling this module.

## Provider configuration

This module requires only the `azurerm` provider. The caller must configure it with credentials that have the `Network Contributor` role (or equivalent) on both the local and remote resource groups. Both VNets must be reachable from the same provider instance (same subscription, or subscriptions the service principal can access).

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_virtual_network_peering.local_to_remote](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [azurerm_virtual_network_peering.remote_to_local](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allow_forwarded_traffic"></a> [allow\_forwarded\_traffic](#input\_allow\_forwarded\_traffic) | Allow forwarded traffic from VMs in the remote VNet into the local VNet and vice versa. Applies to both peering directions. | `bool` | `false` | no |
| <a name="input_allow_gateway_transit"></a> [allow\_gateway\_transit](#input\_allow\_gateway\_transit) | Allow the local VNet to use the remote VNet's gateway or route server. Set to true on the hub VNet that owns the gateway. Applies to the local-to-remote peering only. | `bool` | `false` | no |
| <a name="input_allow_virtual_network_access"></a> [allow\_virtual\_network\_access](#input\_allow\_virtual\_network\_access) | Allow VMs in the remote VNet to access VMs in the local VNet and vice versa. Applies to both peering directions. | `bool` | `true` | no |
| <a name="input_local_resource_group_name"></a> [local\_resource\_group\_name](#input\_local\_resource\_group\_name) | Name of the resource group containing the local virtual network. | `string` | n/a | yes |
| <a name="input_local_vnet_id"></a> [local\_vnet\_id](#input\_local\_vnet\_id) | Full Azure resource ID of the local virtual network. | `string` | n/a | yes |
| <a name="input_local_vnet_name"></a> [local\_vnet\_name](#input\_local\_vnet\_name) | Name of the local (initiating) virtual network. | `string` | n/a | yes |
| <a name="input_remote_resource_group_name"></a> [remote\_resource\_group\_name](#input\_remote\_resource\_group\_name) | Name of the resource group containing the remote virtual network. | `string` | n/a | yes |
| <a name="input_remote_vnet_id"></a> [remote\_vnet\_id](#input\_remote\_vnet\_id) | Full Azure resource ID of the remote virtual network. | `string` | n/a | yes |
| <a name="input_remote_vnet_name"></a> [remote\_vnet\_name](#input\_remote\_vnet\_name) | Name of the remote (target) virtual network. | `string` | n/a | yes |
| <a name="input_use_remote_gateways"></a> [use\_remote\_gateways](#input\_use\_remote\_gateways) | Allow the local VNet to use the remote VNet's gateway or route server. Cannot be set to true if allow\_gateway\_transit is also true. Applies to the local-to-remote peering only. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_local_peering_id"></a> [local\_peering\_id](#output\_local\_peering\_id) | Azure resource ID of the local-to-remote VNet peering object. |
| <a name="output_local_peering_name"></a> [local\_peering\_name](#output\_local\_peering\_name) | Name of the local-to-remote VNet peering object (e.g. <local-vnet>-to-<remote-vnet>). |
| <a name="output_remote_peering_id"></a> [remote\_peering\_id](#output\_remote\_peering\_id) | Azure resource ID of the remote-to-local VNet peering object. |
| <a name="output_remote_peering_name"></a> [remote\_peering\_name](#output\_remote\_peering\_name) | Name of the remote-to-local VNet peering object (e.g. <remote-vnet>-to-<local-vnet>). |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid input produces correctly-named peering resources in both directions.
- Invalid VNet name is rejected by variable validation.
- Invalid resource ID format is rejected by variable validation.
- Invalid resource group name is rejected by variable validation.
- Mutual exclusivity of `use_remote_gateways` and `allow_gateway_transit` is enforced.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Azure subscription) verifies actual VNet peering creation. It is credential-gated and is included as a stub in `tests/integration.tftest.hcl`.
