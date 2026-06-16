# Changelog

All notable changes to the `gcp-account-network-shared-vpc` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: configures a GCP project as a Shared VPC host and attaches service projects via `google_compute_shared_vpc_host_project` and `google_compute_shared_vpc_service_project`.
- Optional subnet-level IAM grants via `google_compute_subnetwork_iam_member` controlled by the `subnet_iam_grants` input.
- Variable validation on `host_project_id` and each entry in `service_project_ids` (GCP project ID format), and minimum length check on `service_project_ids`.
- Outputs: `host_project_id`, `service_project_ids`, `service_project_attachment_ids`, `subnet_iam_grant_ids`.
- `examples/basic/` — minimum invocation attaching one service project with one subnet IAM grant.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering resource attribute checks, multi-project `for_each`, subnet IAM grant creation, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live GCP (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).
