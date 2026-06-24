# Changelog

All notable changes to the `gcp-account-network-cloud-ngfw` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates Cloud NGFW security profile, security profile group, firewall endpoint, and firewall endpoint association for VPC egress inspection.
- Variable validation on `organization_id` (numeric string), `project_id` (GCP project ID format), `zone` (GCP zone format), `network_self_link` (compute self-link format), `resource_prefix` (lowercase alphanumeric/hyphen, 1-30 chars), `severity_overrides` (enumerated action/severity), `threat_overrides` (enumerated action).
- Outputs: `security_profile_id`, `security_profile_name`, `security_profile_group_id`, `security_profile_group_name`, `firewall_endpoint_id`, `firewall_endpoint_self_link`, `firewall_endpoint_state`, `firewall_endpoint_association_id`, `firewall_endpoint_association_state`.
- `examples/basic/` — minimum invocation with `google` provider configured for a GCP organization.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and resource attribute assertions.
- `tests/integration.tftest.hcl` — apply-command stub for live GCP organization (credential-gated).
