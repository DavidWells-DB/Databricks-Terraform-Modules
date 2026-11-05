# azure-account-network-nat

Creates a Standard-SKU NAT gateway + static public IP and associates it with the caller's subnets, giving VNet-injected Databricks subnets an internet egress path. The Azure counterpart of `aws-account-network-egress-internet` (blueprint-gaps N2: the azure classic networking built the VNet only, while `no_public_ip` defaults to true — clusters had no internet path by default). No route table is needed: subnet NAT association installs the 0.0.0.0/0 system route automatically.

## When to use

- azure/classic VNet-injected workspaces using Secure Cluster Connectivity (no public IPs) that need outbound internet (package repos, external data sources).
- Any Azure subnet set needing managed NAT egress.

## When NOT to use

- You bring your own egress (firewall hub, third-party NAT, forced tunneling) — don't double-egress; pass the opt-out at the composition.
- Subnets already associated with a custom route table steering 0.0.0.0/0 elsewhere — a NAT association conflicts with an explicit default route; manage that path yourself.

## Interface notes

- `subnets` is a MAP (caller-chosen keys → subnet resource IDs), never a list: the IDs are typically VNet-module outputs consumed in the same apply, and `for_each` over computed values in a list fails at apply (the twice-proven map pattern).
- azurerm 4.x: the IP association argument is `public_ip_address_id`.

UNVERIFIED live (no credentials at authoring time, 2026-11-05): plan-verified only — the NAT path (subnet association → system route → outbound connectivity) has not been exercised by a live deployment yet.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.70 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 5.12.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway) | resource |
| [azurerm_nat_gateway_public_ip_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association) | resource |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_subnet_nat_gateway_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region for the NAT gateway (e.g. "eastus"). Must match the resource group's region. | `string` | n/a | yes |
| <a name="input_nat_gateway_name"></a> [nat\_gateway\_name](#input\_nat\_gateway\_name) | Name of the NAT gateway. | `string` | n/a | yes |
| <a name="input_public_ip_name"></a> [public\_ip\_name](#input\_public\_ip\_name) | Name of the Standard-SKU public IP that fronts the NAT gateway. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the Azure resource group for the NAT gateway and public IP. | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Map of caller-chosen association names to subnet resource IDs that should egress via the NAT gateway (e.g. { host = module.vnet.host\_subnet\_id, container = module.vnet.container\_subnet\_id }). The KEYS are plan-time constants — that is why this is a map, not a list (for\_each over a list of known-after-apply subnet IDs fails at apply). | `map(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the NAT gateway and public IP. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nat_gateway_id"></a> [nat\_gateway\_id](#output\_nat\_gateway\_id) | Resource ID of the NAT gateway. |
| <a name="output_nat_gateway_name"></a> [nat\_gateway\_name](#output\_nat\_gateway\_name) | Name of the NAT gateway. |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | The static public IP address egressing through the NAT gateway (useful for allow-listing on the destination side). |
| <a name="output_public_ip_id"></a> [public\_ip\_id](#output\_public\_ip\_id) | Resource ID of the public IP fronting the NAT gateway. |
<!-- END_TF_DOCS -->
