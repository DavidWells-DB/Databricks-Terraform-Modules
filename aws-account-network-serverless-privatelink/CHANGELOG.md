# Changelog

All notable changes to the `aws-account-network-serverless-privatelink` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.1] - 2026-10-16

### Removed
- `databricks_account_id` input — dead (caught by tflint): the module derives the allowed-principal ARN from `databricks_gov_shard`'s per-shard AWS account IDs, so the variable was declared-but-unused and its description ("constructs the AWS account principal ARN") was misleading. Breaking only if someone passed it; the module has no known consumers (not yet consumed by any blueprint).


## [0.1.0] - 2026-06-23

### Added
- Initial release of aws-account-network-serverless-privatelink module
- Support for Network Load Balancer creation (internal, type "network")
- IP-based target group for customer resources
- VPC endpoint service with automatic acceptance
- Databricks principal authorization for commercial, GovCloud civilian, and GovCloud DoD
- Security group for NLB egress to target resource
- Configurable listener port (defaults to target port)
- Comprehensive input validation
- Full test coverage (plan and integration tests)
- Basic usage example
- Complete documentation
