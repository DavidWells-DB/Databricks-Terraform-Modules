# Changelog

All notable changes to the `aws-account-network-transit-gateway` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates `aws_ec2_transit_gateway` with configurable ASN, DNS support, VPN ECMP support, and default route table association/propagation settings.
- `aws_ec2_transit_gateway_vpc_attachment` (one per entry in `vpc_attachments`) with explicit opt-out of the default TGW route table.
- `aws_ec2_transit_gateway_route_table` — one shared route table for all VPC attachments.
- `aws_ec2_transit_gateway_route_table_association` and `aws_ec2_transit_gateway_route_table_propagation` — wired for every attachment so all participants can route through the TGW immediately after apply.
- Variable validation on `resource_prefix` (1-24 chars, alphanumeric + hyphens), `tgw_asn` (private ASN ranges), `vpc_attachments` (at least one subnet per attachment), `dns_support`, `vpn_ecmp_support`, `default_route_table_association`, `default_route_table_propagation` (enumerated values).
- Outputs: `transit_gateway_id`, `transit_gateway_arn`, `transit_gateway_owner_id`, `attachment_ids` (map), `route_table_id`, `route_table_ids` (map).
- `examples/basic/` — minimum invocation with two VPC attachments against commercial AWS.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering resource attribute checks and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).
