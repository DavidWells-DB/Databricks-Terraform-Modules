# Changelog

All notable changes to the `azure-account-network-private-endpoints` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.2.0] - 2026-10-27

### Fixed — BREAKING (resource restructure; state migration required)
- **Serialize private-endpoint creation (back_end → front_end → browser_auth via `depends_on`).** Every endpoint creation triggers a workspace update, and the Databricks workspace resource rejects concurrent updates: creating two or more endpoints in parallel fails with `ConcurrentUpdateError` ("Workspace update could not be completed because it has been updated by another process"), leaving the losing endpoint created in Azure but absent from Terraform state (live 2026-10-27, the rc-bd1 journey — first live application of this module).
- The single `for_each` `azurerm_private_endpoint.this` (keyed back_end/front_end/browser_auth) is now three explicit resources. Consumers upgrading from v0.1.0 with existing endpoints must `terraform state mv` them:
  - `module.pe.azurerm_private_endpoint.this["back_end"]` → `module.pe.azurerm_private_endpoint.back_end`
  - `module.pe.azurerm_private_endpoint.this["front_end"]` → `module.pe.azurerm_private_endpoint.front_end[0]`
  - `module.pe.azurerm_private_endpoint.this["browser_auth"]` → `module.pe.azurerm_private_endpoint.browser_auth[0]`
- Outputs unchanged (same names, same conditional-null semantics).


### Fixed
- **Pin `azurerm < 5.0`.** azurerm 5.x removed `private_dns_zone_name` and `resource_group_name` from `azurerm_private_dns_zone_virtual_network_link`; the module targets the 3.x/4.x API. The unbounded `>= 3.63` constraint let CI resolve 5.x and fail. (Found by the new unit-test CI, E10.)

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates `azurerm_private_dns_zone` (privatelink.azuredatabricks.net), `azurerm_private_dns_zone_virtual_network_link` (spoke + optional hub VNets), and `azurerm_private_endpoint` resources for Azure Databricks Private Link.
- Back-end private endpoint (`databricks_ui_api`) always created.
- Optional front-end private endpoint (`databricks_ui_api`) via `enable_front_end_pe`.
- Optional browser authentication private endpoint (`browser_authentication`) via `enable_browser_auth_pe`.
- Hub VNet DNS zone linking via `hub_vnet_ids` input.
- Variable validation on `resource_group_name` (Azure naming rules), `location` (lowercase alphanumeric), `workspace_resource_id` (Databricks workspace ARM path), `pe_subnet_id` (subnet ARM path), `vnet_id` (VNet ARM path), `hub_vnet_ids` (each entry validated as VNet ARM path).
- Outputs: `private_dns_zone_id`, `private_dns_zone_name`, `back_end_pe_id`, `back_end_pe_private_ip`, `front_end_pe_id`, `front_end_pe_private_ip`, `browser_auth_pe_id`, `browser_auth_pe_private_ip`, `dns_zone_virtual_network_link_ids`.
- `examples/basic/` — minimum invocation with back-end PE only.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering conditional PE creation and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Azure (credential-gated; includes tier-failure case placeholder per the Databricks module rules Rule 4.1).
