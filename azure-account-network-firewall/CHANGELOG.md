# Changelog

All notable changes to the `azure-account-network-firewall` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates Azure Firewall, detached firewall policy, IP group, public IP, forced-tunnel route table, and spoke subnet associations.
- `service_tag_rules` input for Databricks-specific Azure Service Tag network rules (e.g., `AzureDatabricks`, `Storage.EastUs`).
- `allowed_spoke_cidr_ranges` input populates an `azurerm_ip_group` used as the source in network rules.
- `firewall_sku_tier` input (default `"Premium"`) controls both `azurerm_firewall` and `azurerm_firewall_policy` SKU.
- Variable validation on `resource_group_name`, `firewall_name`, `firewall_subnet_id`, `spoke_subnet_ids`, `allowed_spoke_cidr_ranges`, `service_tag_rules` (priority bounds, allowed actions, allowed protocols), and `firewall_sku_tier`.
- Outputs: `firewall_id`, `firewall_private_ip`, `firewall_public_ip`, `firewall_public_ip_id`, `firewall_policy_id`, `route_table_id`, `ip_group_id`.
- `examples/basic/` — minimum invocation demonstrating hub-spoke firewall deployment for Databricks.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and resource attribute checks.
- `tests/integration.tftest.hcl` — apply-command stub for live Azure subscription (credential-gated; includes tier-failure placeholder per DATABRICKS_RULES Rule 4.1).
