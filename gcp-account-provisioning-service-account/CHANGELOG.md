# Changelog

All notable changes to the `gcp-account-provisioning-service-account` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates GCP service account, custom IAM role, project IAM binding, and registers the account as a Databricks account admin via `databricks_user` + `databricks_user_role`.
- Custom role with Databricks-documented minimum permissions for GKE workspace provisioning (compute, KMS, GKE, Shared VPC, IAM, serviceusage).
- `delegate_emails` input for `roles/iam.serviceAccountTokenCreator` bindings on the provisioner service account.
- Variable validation on `project_id` (GCP project ID constraints), `databricks_account_id` (UUID format), and `resource_prefix` (length + character set).
- Locals computing stable `service_account_id` and `custom_role_id` from `resource_prefix` with hyphen-to-underscore normalisation for the role ID.
- Outputs: `service_account_email`, `service_account_id`, `service_account_unique_id`, `custom_role_id`, `databricks_user_id`.
- `examples/basic/` — minimum invocation against a GCP project.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and resource attribute checks.
- `tests/integration.tftest.hcl` — apply-command stub for live GCP + Databricks account (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).
