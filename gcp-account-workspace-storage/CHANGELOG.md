# Changelog

All notable changes to the `gcp-account-workspace-storage` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: creates GCS root storage bucket + `databricks_mws_storage_configurations`.
- IAM bindings: `roles/storage.objectAdmin` and `roles/storage.legacyBucketReader` for the Databricks-managed service account.
- Optional CMEK support via `kms_key_name` input.
- Variable validation on `resource_prefix` (GCS naming constraints), `databricks_service_account_email` (service account format), and `kms_key_name` (KMS resource name format).
- Computed local `bucket_name` derived from `resource_prefix` with `-root-storage` suffix.
- Outputs: `storage_configuration_id`, `bucket_name`, `bucket_url`, `bucket_self_link`.
- `examples/basic/` — minimum invocation against a GCP project.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering bucket name computation, variable validations, and resource attribute checks.
- `tests/integration.tftest.hcl` — apply-command stub for live GCP + Databricks (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).
