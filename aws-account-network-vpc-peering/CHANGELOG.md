# Changelog

All notable changes to the `aws-account-network-vpc-peering` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates `aws_vpc_peering_connection`, `aws_vpc_peering_connection_accepter`, and bidirectional `aws_route` resources in both requester and accepter VPCs.
- Supports same-account, cross-account, same-region, and inter-region VPC peering.
- Variable validation on all VPC IDs (`vpc-<hex>`), route table IDs (`rtb-<hex>`), CIDR blocks (valid IPv4 CIDR), accepter account ID (12-digit), and accepter region (AWS region format).
- `locals.tf` with a `common_tags` merge applied to all taggable resources.
- Outputs: `peering_connection_id`, `peering_connection_status`, `requester_route_ids`, `accepter_route_ids`.
- `examples/basic/` — minimum same-account same-region invocation.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and resource attribute checks.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS integration (credential-gated).
