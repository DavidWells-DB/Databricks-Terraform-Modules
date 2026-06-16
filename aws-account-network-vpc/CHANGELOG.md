# Changelog

All notable changes to the `aws-account-network-vpc` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

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
