# Changelog

All notable changes to the `aws-account-network-connectivity-config` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: creates `databricks_mws_network_connectivity_config` at the Databricks account level.
- Variable validation on `databricks_gov_shard` (null, civilian, dod), `region` (AWS region format), and `name` (Databricks-documented 3-30 character alphanumeric/hyphen/underscore constraint).
- Outputs: `network_connectivity_config_id`, `name`, `region`, `creation_time`.
- `examples/basic/` — minimum invocation against commercial AWS.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and resource attribute checks.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks account (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES.md Rule 4.1).
