# Changelog

All notable changes to the `aws-account-network-vpc` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.2.0] - 2026-08-03

### Fixed
- **`create_before_destroy` on `databricks_mws_networks` — enables in-place back-end PrivateLink adoption on a LIVE workspace.** The `vpc_endpoints` block is ForceNew, so adopting PrivateLink replaces the network *registration*; without `create_before_destroy` Terraform tried delete-then-create and the delete failed with `cannot delete mws networks: INVALID_STATE: Network is being used by active workspace`. Creating the replacement first lets the workspace re-point `network_id` (which is in the `mws_workspaces` running-update allowlist) before the old registration is removed. **The VPC does not change** — PrivateLink adds interface endpoints to the existing VPC; only this metadata-only registration is re-created. Found by a live evolution-journey apply; the pattern existed in the prior-art stack and was dropped in this module. Callers must also vary `network_name` when PrivateLink is toggled so the create-before-destroy replacement doesn't collide (see `networking/aws/basic` v0.3.2).

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates AWS VPC, private/public/PrivateLink subnets, route tables, Databricks-required security group, and `databricks_mws_networks` registration.
- GovCloud parameterization via `databricks_gov_shard` input (commercial, civilian, dod) per DATABRICKS_RULES.md Rule 1.5.
- Optional public subnets via `public_subnet_cidrs` (for NAT gateway use with aws-account-network-egress-internet).
- Optional PrivateLink-dedicated subnets via `privatelink_subnet_cidrs` (for use with aws-account-network-privatelink-endpoints).
- Optional PrivateLink wiring via `vpc_endpoint_ids` input — conditionally includes `vpc_endpoints` block in `databricks_mws_networks`.
- Per-private-subnet route tables exposed via `private_route_table_ids` output for downstream egress and VPC endpoint modules.
- Variable validation on `databricks_gov_shard`, `resource_prefix` (length + charset), `vpc_cidr` (valid CIDR), `private_subnet_cidrs` (minimum 2), `public_subnet_cidrs` (valid CIDRs), `privatelink_subnet_cidrs` (valid CIDRs), `azs` (minimum 2, AZ name format), `network_name` (length + charset).
- Outputs: `vpc_id`, `private_subnet_ids`, `public_subnet_ids`, `privatelink_subnet_ids`, `security_group_id`, `databricks_network_id`, `private_route_table_ids`, `vpc_cidr`.
- `examples/basic/` — minimum invocation against commercial AWS with two private subnets.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations, resource attribute checks, and PrivateLink conditional logic.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS + Databricks (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).
