# Changelog

All notable changes to this module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-16

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
