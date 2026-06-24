# Changelog

All notable changes to the `gcp-account-network-cloud-nat` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates `google_compute_router` and `google_compute_router_nat` for private-subnet internet egress.
- Variable validation on `network_self_link` and `subnetwork_self_link` (fully-qualified Compute API self-link format), `resource_prefix` (GCP naming constraints, 50-char cap), `min_ports_per_vm` (power-of-2 enumeration per GCP Cloud NAT requirements), and `log_config_filter` (enumerated GCP values).
- Optional Cloud NAT logging via `log_config_enable` and `log_config_filter` variables; logging block omitted when disabled.
- Outputs: `router_id`, `router_name`, `router_self_link`, `nat_id`, `nat_name`.
- `examples/basic/` — minimum invocation for a private Databricks subnet.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and resource attribute assertions.
- `tests/integration.tftest.hcl` — apply-command stub for live GCP (credential-gated).
