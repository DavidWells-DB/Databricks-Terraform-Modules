# Changelog

All notable changes to the `azure-account-network-vnet-peering` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: creates bidirectional `azurerm_virtual_network_peering` (one per direction) between two Azure VNets.
- Variable validation on `local_vnet_name` and `remote_vnet_name` (Azure VNet name constraints), `local_vnet_id` and `remote_vnet_id` (Azure resource ID format), `local_resource_group_name` and `remote_resource_group_name` (Azure resource group name constraints).
- Mutual-exclusivity validation: `use_remote_gateways` and `allow_gateway_transit` cannot both be true.
- Gateway settings correctly reversed on the return peering leg.
- Outputs: `local_peering_id`, `remote_peering_id`, `local_peering_name`, `remote_peering_name`.
- `examples/basic/` — minimum invocation peering a spoke VNet to a hub VNet.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering resource naming, all variable validations, and gateway mutual exclusivity.
- `tests/integration.tftest.hcl` — apply-command stub for live Azure (credential-gated; includes tier-failure case stub per DATABRICKS_RULES Rule 4.1).
