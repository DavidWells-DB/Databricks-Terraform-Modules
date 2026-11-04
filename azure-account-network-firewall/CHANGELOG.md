# Changelog

All notable changes to the `azure-account-network-firewall` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.2.0] - 2026-10-20 (entry added late 2026-11-04 — this version shipped without a CHANGELOG entry; recorded retroactively from the commit history)

### Changed — fixed a real apply-breaking interface defect (E23-class, found by the live burn-in)
- `spoke_subnet_ids` (list) replaced by `spoke_subnets` (map of caller-chosen NAME to subnet ID). The list form failed at apply when the spoke subnets were created in the SAME run ("Invalid for_each argument" — for_each keys must be plan-time known). The map form is the twice-proven pattern (also in aws-account-network-vpc v0.3.0); the re-run of the exact failing composition now applies, is idempotent (exit 0), and destroys clean.

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
- `tests/integration.tftest.hcl` — apply-command stub for live Azure subscription (credential-gated; includes tier-failure placeholder per the Databricks module rules Rule 4.1).
