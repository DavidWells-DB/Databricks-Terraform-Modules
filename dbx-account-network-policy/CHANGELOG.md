# Changelog

All notable changes to the `dbx-account-network-policy` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.2.2] - 2026-08-01

### Fixed
- **Perpetual in-place diff on `policy_enforcement`.** The API defaults `enforcement_mode` to `ENFORCED` and returns it, but the module did not set `policy_enforcement`, so every plan tried to remove it. Now set explicitly via a new `enforcement_mode` input (default `ENFORCED`).

## [0.2.1] - 2026-08-01

### Fixed
- **Perpetual replacement / idempotency bug.** The resource did not set `account_id`, so the provider treated it as computed (known-after-apply) and forced replacement on every plan — a re-apply with no changes would destroy and recreate the policy. Now set from a new **required** `databricks_account_id` input. *Breaking:* callers must supply `databricks_account_id`. Verified fixed by apply testing (a second plan now shows no changes).

## [0.2.0] - 2026-08-01

### Fixed
- **`egress_mode` used invalid enum values.** Was `ALLOW_LIST`/`UNRESTRICTED`, but the provider's `restriction_mode` requires `RESTRICTED_ACCESS`/`FULL_ACCESS` — the wrong value crashed the provider at apply. Now `RESTRICTED_ACCESS` (default) / `FULL_ACCESS`, with corrected validation. **Breaking** for any caller that set `egress_mode` explicitly.
- **`internet_destination_type` used invalid enum values** (`CIDR`/`FQDN`) in docs, defaults, and the example. The provider currently supports only `DNS_NAME`; added a default of `DNS_NAME` and validation. Example updated to DNS-name destinations.

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
