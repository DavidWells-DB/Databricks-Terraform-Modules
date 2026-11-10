# Changelog

All notable changes to the `aws-account-vpc` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.0] - 2026-11-10

### Added
- Initial module: the pure AWS-side VPC for a Databricks classic workspace (VPC, private/public/privatelink subnets, per-subnet private route tables, the Databricks-required security group). NO Databricks provider — split out of aws-account-network-vpc (the three-piece split) so BYO-VPC consumers can take the cloud half alone; pair with dbx-account-mws-networks for the registration, or use aws-account-network-vpc for the one-call composition.
- Plan tests with mock_provider covering the subnet/route-table derivations and variable validations.
