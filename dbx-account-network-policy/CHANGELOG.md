# Changelog

All notable changes to the `dbx-account-network-policy` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates Databricks account-level network policy for serverless compute egress control.
- Egress mode parameterization via `egress_mode` input (ALLOW_LIST, UNRESTRICTED).
- Variable validation on `policy_name` (1-32 chars, alphanumeric + hyphens), `egress_mode` (enum validation).
- Support for `allowed_internet_destinations` (CIDR blocks and FQDNs with optional type).
- Support for `allowed_storage_destinations` (AWS S3 buckets and Azure storage accounts with optional region/service).
- Outputs: `network_policy_id`, `policy_name`, `egress_mode`.
- `examples/basic/` — invocation with ALLOW_LIST mode, internet destinations, and storage destinations.
- `tests/plan.tftest.hcl` — 12 plan-command cases with `mock_provider` covering egress mode validation, policy name validation, and destination configuration.
