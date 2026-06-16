# Changelog

All notable changes to the `gcp-account-vpc-service-controls` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: creates VPC Service Controls perimeter for GCP projects.
- Variable validation on `perimeter_name` (alphanumeric + underscores, max 50 chars), `perimeter_title` (1-200 chars), `protected_project_numbers` (minimum 1).
- Automatic normalization of `access_policy_id` and `protected_project_numbers` to full resource name format.
- Support for ingress and egress policies with full policy rule structure.
- Outputs: `perimeter_id`, `perimeter_name`, `restricted_services`, `protected_projects`.
- `examples/basic/` — minimum invocation with default restricted services.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering variable validations and resource attributes.
