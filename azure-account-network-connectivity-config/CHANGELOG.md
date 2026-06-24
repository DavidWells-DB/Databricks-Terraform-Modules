# Changelog

All notable changes to the `azure-account-network-connectivity-config` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates `databricks_mws_network_connectivity_config` for Azure serverless private connectivity.
- Optional `databricks_account_network_policy` created when `allowed_internet_destinations` is set (RESTRICTED_ACCESS mode); omitted otherwise.
- Variable validation on `name` (provider-documented constraint `^[0-9a-zA-Z-_]{3,30}$`) and `internet_destination_type` (enumerated: `DNS_NAME`).
- Outputs: `network_connectivity_config_id`, `ncc_name`, `region`, `network_policy_id`.
- `examples/basic/` — minimum invocation without internet restrictions (NCC only).
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering NCC creation, conditional network policy creation, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Azure + Databricks account (credential-gated; includes tier-failure case placeholder per DATABRICKS_RULES Rule 4.1).
