# azure-account-network-private-endpoints

Creates Azure Private Endpoints to an Azure Databricks workspace and the private DNS zone + VNet links required to resolve the workspace URL to private IPs. Always creates the back-end (`databricks_ui_api`) private endpoint; optionally adds a front-end endpoint and/or a `browser_authentication` endpoint.

## What this module abstracts

"The private network path to a Databricks workspace" — the private endpoint(s), the `privatelink.azuredatabricks.net` DNS zone, and the VNet link(s) that make the workspace URL resolve privately. These resources are always deployed together; deploying the endpoint without the DNS zone leaves clients unable to reach the workspace. Pairing them produces a real abstraction per DATABRICKS_RULES.md Rule 1.4.

## When to use

- You are deploying an Azure Databricks workspace with `public_network_access_enabled = false` (No Public IP / Private Link).
- You need clients inside the VNet (or connected hub VNets) to resolve the workspace URL to a private IP.
- You want a single module that wires the private endpoint, DNS zone, and VNet link together.

## When NOT to use

- Your workspace uses public network access with no private link requirement — skip this module entirely.
- Your organization manages private DNS zones centrally (hub-and-spoke with central DNS) — set `hub_vnet_ids` to link the zone to the hub, or manage the DNS zone outside this module and link it separately.
- You are on AWS or GCP — they use different PrivateLink / PSC mechanisms with distinct modules.

## Minimum platform tier

**Premium.** Databricks Private Link is a Premium-tier feature. Applying this module against a Standard-tier workspace is harmless to the Azure resources, but the workspace will not enforce private-only access. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

This module uses `azurerm` only. No Databricks provider is required. The caller must configure the `azurerm` provider targeting the correct Azure subscription and environment.

For **Azure Government**, configure the provider in the root composition:

```hcl
provider "azurerm" {
  environment = "usgovernment"
  features {}
}
```

No module-level changes are needed for Azure Government; the `azurerm` provider transparently routes to government endpoints.

## Private endpoint types

| Endpoint | Variable | Sub-resource | Use case |
|---|---|---|---|
| Back-end | always created | `databricks_ui_api` | Driver → control plane API; cluster → DBFS |
| Front-end | `enable_front_end_pe = true` | `databricks_ui_api` | Browser / REST API clients outside the injected VNet |
| Browser auth | `enable_browser_auth_pe = true` | `browser_authentication` | SSO OAuth callback when public network access is disabled |

Source: https://learn.microsoft.com/azure/databricks/security/network/classic/private-link-simplified

## Hub VNet DNS linking

When using a hub-and-spoke topology, pass hub VNet resource IDs to `hub_vnet_ids`. Each hub VNet receives a DNS zone virtual network link so that clients in the hub can resolve the workspace URL to the private endpoint IP.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.63 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.63 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_private_dns_zone.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_enable_browser_auth_pe"></a> [enable\_browser\_auth\_pe](#input\_enable\_browser\_auth\_pe) | When true, creates a browser\_authentication private endpoint. Required for SSO callback flows (web browser authentication) when public network access is disabled. | `bool` | `false` | no |
| <a name="input_enable_front_end_pe"></a> [enable\_front\_end\_pe](#input\_enable\_front\_end\_pe) | When true, creates an additional front-end private endpoint (sub-resource type `databricks_ui_api` on the `publicFrontEnd` group). Required when public network access is disabled and clients access Databricks from outside the injected VNet. | `bool` | `false` | no |
| <a name="input_hub_vnet_ids"></a> [hub\_vnet\_ids](#input\_hub\_vnet\_ids) | Optional list of hub VNet resource IDs to also link to the private DNS zone. Use when the DNS zone lives in the spoke but hub VNets must resolve the workspace URL. Defaults to an empty list (no hub links). | `list(string)` | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for private endpoint resources (e.g., "eastus", "westeurope"). Must match the region of the Databricks workspace. | `string` | n/a | yes |
| <a name="input_pe_subnet_id"></a> [pe\_subnet\_id](#input\_pe\_subnet\_id) | Azure resource ID of the subnet in which to place private endpoint network interfaces. Private endpoint network policies must be disabled on this subnet. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the Azure resource group in which to create private endpoint and DNS resources. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources created by this module. | `map(string)` | `{}` | no |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | Azure resource ID of the VNet to link to the private DNS zone. This is the spoke VNet that contains the Databricks subnets. | `string` | n/a | yes |
| <a name="input_workspace_resource_id"></a> [workspace\_resource\_id](#input\_workspace\_resource\_id) | Azure resource ID of the Databricks workspace (e.g., /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Databricks/workspaces/<name>). | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_back_end_pe_id"></a> [back\_end\_pe\_id](#output\_back\_end\_pe\_id) | Azure resource ID of the back-end private endpoint (databricks\_ui\_api sub-resource). Always created. |
| <a name="output_back_end_pe_private_ip"></a> [back\_end\_pe\_private\_ip](#output\_back\_end\_pe\_private\_ip) | Private IP address allocated to the back-end private endpoint NIC. Useful for custom DNS or network ACL rules. |
| <a name="output_browser_auth_pe_id"></a> [browser\_auth\_pe\_id](#output\_browser\_auth\_pe\_id) | Azure resource ID of the browser\_authentication private endpoint. null when enable\_browser\_auth\_pe is false. |
| <a name="output_browser_auth_pe_private_ip"></a> [browser\_auth\_pe\_private\_ip](#output\_browser\_auth\_pe\_private\_ip) | Private IP address of the browser\_authentication private endpoint NIC. null when enable\_browser\_auth\_pe is false. |
| <a name="output_dns_zone_virtual_network_link_ids"></a> [dns\_zone\_virtual\_network\_link\_ids](#output\_dns\_zone\_virtual\_network\_link\_ids) | Map of DNS zone virtual network link names to their Azure resource IDs. Keys are 'spoke' and 'hub\_<index>' for any hub VNets. |
| <a name="output_front_end_pe_id"></a> [front\_end\_pe\_id](#output\_front\_end\_pe\_id) | Azure resource ID of the front-end private endpoint. null when enable\_front\_end\_pe is false. |
| <a name="output_front_end_pe_private_ip"></a> [front\_end\_pe\_private\_ip](#output\_front\_end\_pe\_private\_ip) | Private IP address of the front-end private endpoint NIC. null when enable\_front\_end\_pe is false. |
| <a name="output_private_dns_zone_id"></a> [private\_dns\_zone\_id](#output\_private\_dns\_zone\_id) | Azure resource ID of the privatelink.azuredatabricks.net private DNS zone. |
| <a name="output_private_dns_zone_name"></a> [private\_dns\_zone\_name](#output\_private\_dns\_zone\_name) | Name of the private DNS zone (privatelink.azuredatabricks.net). Useful for additional VNet links added outside this module. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Back-end private endpoint is always planned.
- Front-end endpoint is planned only when `enable_front_end_pe = true`.
- Browser auth endpoint is planned only when `enable_browser_auth_pe = true`.
- Invalid `resource_group_name` is rejected by variable validation.
- Invalid `workspace_resource_id` format is rejected by variable validation.
- Invalid `pe_subnet_id` format is rejected by variable validation.
- Invalid `vnet_id` format is rejected by variable validation.
- Invalid `location` format is rejected by variable validation.
- Invalid entries in `hub_vnet_ids` are rejected by variable validation.
- DNS zone name is always `privatelink.azuredatabricks.net`.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Azure subscription) verifies actual private endpoint creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
