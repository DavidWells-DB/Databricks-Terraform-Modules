# azure-account-network-firewall

Creates an Azure Firewall with a detached firewall policy, an IP group for spoke CIDRs, a forced-tunnel route table (0.0.0.0/0 → firewall private IP), and associates that route table with the caller-supplied spoke subnets. The firewall policy carries Databricks-specific network rules targeting Azure Service Tags (e.g., `AzureDatabricks`, `Storage.EastUs`) to control egress from Databricks compute subnets through the firewall.

## What this module abstracts

"The Azure Firewall that controls egress from Databricks compute subnets" — firewall resource, firewall policy, IP group, public IP, route table, and subnet associations are one indivisible deployment unit for a hub-spoke topology. Splitting them produces thin wrappers that the caller must re-wire every time; this module encapsulates the full firewall + routing pairing per DATABRICKS_RULES.md Rule 1.2.

## When to use

- You are building a hub-spoke network topology for Azure Databricks and want all spoke egress inspected and filtered by Azure Firewall before reaching the internet or Azure services.
- You need to allow Databricks control-plane traffic to Azure service tags (e.g., `AzureDatabricks`, `Storage.EastUs`, `EventHub`) without managing explicit IP address lists.
- You want forced-tunnel routing so that no spoke subnet can bypass the firewall via the internet gateway directly.

## When NOT to use

- You already have an Azure Firewall deployed and only need to add rule collections — reference the existing firewall's policy ID and add `azurerm_firewall_policy_rule_collection_group` resources in your root composition.
- You want NAT-only egress without inspection — use a NAT Gateway attached to a public IP directly.
- You need to inspect east-west (spoke-to-spoke) traffic — Azure Firewall Premium with forced hub routing handles this, but you must supply the appropriate rules via `service_tag_rules`.

## Minimum platform tier

**Premium.** Deploying Azure Firewall for Databricks egress control is a Premium-tier use case. The Azure Firewall resource itself does not require a Databricks tier, but the workspaces whose egress it controls must be Premium or above to support the required security controls. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

This module uses only the `azurerm` provider. No Databricks provider is required — the firewall is a pure Azure infrastructure resource. Configure the `azurerm` provider in your root composition with the appropriate `subscription_id`.

Azure Government is supported via `environment = "usgovernment"` set on the `azurerm` provider in the root composition. No module-level parameterization is required; this is a provider-level concern per DATABRICKS_RULES.md Rule 1.5 (Azure Government is parameterized via the provider `environment` setting, handled in root compositions).

## Firewall SKU

The `firewall_sku_tier` variable defaults to `"Premium"`. Azure Firewall Premium enables TLS inspection and IDPS, which are recommended for Databricks workloads. `"Standard"` is available for workloads that do not require TLS inspection. Both the firewall and its policy must use the same SKU tier.

## Service tag rules

Pass Databricks-specific service tag rules via `service_tag_rules`. Each rule specifies the Azure Service Tags to allow (e.g., `AzureDatabricks`, `Storage.EastUs`), destination ports, and protocols. Service tags are preferred over explicit CIDR lists because Microsoft maintains the IP prefixes behind each tag. Refer to the [Databricks Azure network requirements documentation](https://learn.microsoft.com/en-us/azure/databricks/security/network/classic/udr) for the current list of required service tags and ports.

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
| [azurerm_firewall.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall) | resource |
| [azurerm_firewall_policy.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy) | resource |
| [azurerm_firewall_policy_rule_collection_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_ip_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ip_group) | resource |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_route.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) | resource |
| [azurerm_route_table.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_subnet_route_table_association.spoke](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_spoke_cidr_ranges"></a> [allowed\_spoke\_cidr\_ranges](#input\_allowed\_spoke\_cidr\_ranges) | List of CIDR ranges for spoke VNet subnets. Used to populate the source IP group in the firewall network rules that permit spoke egress traffic through the firewall. | `list(string)` | n/a | yes |
| <a name="input_firewall_name"></a> [firewall\_name](#input\_firewall\_name) | Name for the Azure Firewall. Used as the base name for the firewall, policy, IP group, public IP, and route table resources. | `string` | n/a | yes |
| <a name="input_firewall_sku_tier"></a> [firewall\_sku\_tier](#input\_firewall\_sku\_tier) | SKU tier for the Azure Firewall and its policy. "Standard" or "Premium". Premium enables TLS inspection and IDPS; recommended for SNI-based Databricks egress filtering. | `string` | `"Premium"` | no |
| <a name="input_firewall_subnet_id"></a> [firewall\_subnet\_id](#input\_firewall\_subnet\_id) | Resource ID of the AzureFirewallSubnet into which the firewall is deployed. The subnet must be named exactly "AzureFirewallSubnet" and be at least /26. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region where all firewall resources are created (e.g. "eastus", "westeurope"). Must match the resource group's region. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the Azure resource group in which to create all firewall resources. | `string` | n/a | yes |
| <a name="input_service_tag_rules"></a> [service\_tag\_rules](#input\_service\_tag\_rules) | List of network rule objects that permit traffic from spoke subnets to Databricks-specific<br/>Azure service tags. Each rule targets a set of Azure service tags (e.g. ["AzureDatabricks",<br/>"Storage.EastUs"]) on the specified ports and protocols. Priority must be unique per rule<br/>within the rule collection group and in the range 100-65000. Action must be "Allow" or "Deny".<br/>Protocols must each be one of "Any", "TCP", "UDP", "ICMP". | <pre>list(object({<br/>    name              = string<br/>    priority          = number<br/>    action            = string<br/>    destination_tags  = list(string)<br/>    destination_ports = list(string)<br/>    protocols         = list(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_spoke_subnet_ids"></a> [spoke\_subnet\_ids](#input\_spoke\_subnet\_ids) | List of spoke subnet resource IDs whose egress should be forced through the firewall. A forced-tunnel route table (0.0.0.0/0 → firewall private IP) is created and associated with each subnet. At least one subnet ID is required. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all Azure resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_firewall_id"></a> [firewall\_id](#output\_firewall\_id) | Resource ID of the Azure Firewall. Useful for cross-referencing in diagnostic settings, monitoring, or policy assignments. |
| <a name="output_firewall_policy_id"></a> [firewall\_policy\_id](#output\_firewall\_policy\_id) | Resource ID of the Azure Firewall Policy. Pass to additional azurerm\_firewall\_policy\_rule\_collection\_group resources that extend rule collections post-deployment. |
| <a name="output_firewall_private_ip"></a> [firewall\_private\_ip](#output\_firewall\_private\_ip) | Private IP address of the Azure Firewall front-end interface. Used as the next-hop in forced-tunnel routes and for verifying traffic flow. |
| <a name="output_firewall_public_ip"></a> [firewall\_public\_ip](#output\_firewall\_public\_ip) | Public IP address associated with the Azure Firewall. Required for allowlisting outbound traffic in external services or for auditing. |
| <a name="output_firewall_public_ip_id"></a> [firewall\_public\_ip\_id](#output\_firewall\_public\_ip\_id) | Resource ID of the public IP address associated with the Azure Firewall. Useful for DDoS protection plan association at the root composition. |
| <a name="output_ip_group_id"></a> [ip\_group\_id](#output\_ip\_group\_id) | Resource ID of the IP group representing spoke CIDR ranges. Useful for referencing in additional firewall policy rule collections that need to match on the same source addresses. |
| <a name="output_route_table_id"></a> [route\_table\_id](#output\_route\_table\_id) | Resource ID of the spoke route table containing the forced-tunnel (0.0.0.0/0 → firewall) route. The module associates this route table with each subnet in spoke\_subnet\_ids; expose here for cross-referencing. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each variable validation (resource_group_name format, firewall_name constraints, subnet ID format, CIDR validity, service_tag_rules priority/action/protocol bounds, firewall_sku_tier allowed values)
- Resource attribute checks (firewall name, policy name, route table BGP propagation, forced-tunnel route next-hop type)

Run with `terraform test` from the module root.

An apply-command integration test (against a real Azure subscription) verifies actual firewall and route table creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
