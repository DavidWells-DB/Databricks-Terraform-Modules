# Changelog

All notable changes to the `azure-account-network-private-endpoints` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

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
- `tests/integration.tftest.hcl` — apply-command stub for live Azure (credential-gated; includes tier-failure case placeholder per DATABRICKS_RULES Rule 4.1).
