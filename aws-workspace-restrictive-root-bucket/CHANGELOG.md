# Changelog

All notable changes to the `aws-workspace-restrictive-root-bucket` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial release of `aws-workspace-restrictive-root-bucket` module
- Applies least-privilege S3 bucket policy to Databricks workspace root storage bucket
- Scopes write access to workspace-specific paths: `ephemeral/{region}-prod/{workspace_id}/*`, `user/hive/warehouse/*`, `FileStore/*`
- Enforces principal tag condition: `aws:PrincipalTag/DatabricksAccountId`
- Denies non-HTTPS access (SSL enforcement)
- Supports AWS commercial and GovCloud (civilian and DoD shards)
- Validates bucket name, workspace ID, region, and Databricks account ID formats
- Includes plan-based tests (`tests/plan.tftest.hcl`) covering shard resolution, variable validation, and policy content
- Includes integration test skeleton (`tests/integration.tftest.hcl`) for apply-command validation
- Includes basic example (`examples/basic/`) demonstrating typical usage
