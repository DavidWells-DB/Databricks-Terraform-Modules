# Changelog

All notable changes to the `aws-account-network-privatelink-endpoints` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates AWS PrivateLink interface endpoints (workspace REST API + SCC relay + optional service-direct), registers each as `databricks_mws_vpc_endpoint`, and creates `databricks_mws_private_access_settings`.
- GovCloud parameterization via `databricks_gov_shard` input (commercial, civilian, dod) — drives distinct endpoint service attachment URIs per shard.
- Built-in region map for workspace and SCC relay endpoint service names covering all commercial Databricks regions (16 regions) and GovCloud civilian/DoD.
- `custom_service_attachment_uris` input to override the built-in region map for new or unlisted regions.
- `enable_service_direct` input for the optional third (service-direct) VPC endpoint; enforced absent in GovCloud via documentation.
- AWS security group with ports 443, 2443 (FIPS/CSP), and 6666 (SCC relay) opened for configurable CIDR ingress.
- Variable validation on `databricks_gov_shard`, `vpc_id` (format), `region` (format), `privatelink_subnet_ids` (count + format), `private_access_settings_name`, `workspace_vpc_endpoint_name`, `relay_vpc_endpoint_name`, `security_group_name`, `private_access_level`.
- Outputs: `workspace_vpc_endpoint_id`, `relay_vpc_endpoint_id`, `service_direct_vpc_endpoint_id`, `private_access_settings_id`, `security_group_id`, `workspace_aws_vpc_endpoint_id`, `relay_aws_vpc_endpoint_id`, `service_direct_aws_vpc_endpoint_id`, `workspace_service_name`, `relay_service_name`.
- `examples/basic/` — minimum invocation against commercial AWS (us-east-1).
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering gov_shard URI branching, variable validations, service-direct conditional, and custom override.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS + Databricks (credential-gated; includes placeholder for Enterprise tier-failure case per DATABRICKS_RULES Rule 4.1).
