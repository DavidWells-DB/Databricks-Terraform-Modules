# Changelog

All notable changes to the `azure-account-network-vnet` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates Azure VNet + host subnet + container subnet + NSG + subnet-NSG associations for Databricks VNet injection.
- Optional private endpoint subnet (created when both `pe_subnet_name` and `pe_subnet_cidr` are provided).
- Service delegation (`Microsoft.Databricks/workspaces`) on host and container subnets as required for VNet injection.
- `lifecycle { ignore_changes = [security_rule] }` on the NSG to preserve Databricks control-plane-injected rules.
- Variable validation on all name inputs (Azure resource naming rules) and all CIDR inputs.
- Outputs: `vnet_id`, `vnet_name`, `host_subnet_id`, `host_subnet_name`, `container_subnet_id`, `container_subnet_name`, `pe_subnet_id`, `nsg_id`, `nsg_name`.
- `examples/basic/` — minimum invocation with and without optional PE subnet.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering PE subnet toggle and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Azure (credential-gated; includes placeholder for tier-failure case per DATABRICKS_RULES Rule 4.1).
