# Changelog

All notable changes to the `aws-account-network-egress-internet` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates `aws_internet_gateway`, `aws_eip` (per NAT), `aws_nat_gateway` (per NAT), and `aws_route` (0.0.0.0/0 → NAT) on each private route table.
- `nat_gateway_count` input for HA multi-AZ deployments (default 1).
- Variable validation on `vpc_id` (vpc- prefix pattern), `public_subnet_ids` (subnet- prefix pattern, length >= 1), `private_route_table_ids` (rtb- prefix pattern, length >= 1), `nat_gateway_count` (>= 1).
- Outputs: `internet_gateway_id`, `nat_gateway_ids`, `nat_public_ips`, `nat_gateway_id` (convenience alias), `nat_public_ip` (convenience alias).
- `examples/basic/` — minimum invocation against commercial AWS.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and resource attribute checks.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS (credential-gated).
