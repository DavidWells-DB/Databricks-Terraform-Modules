# Changelog

All notable changes to the `dbx-account-mws-networks` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.0] - 2026-11-10

### Added
- Initial module: the pure Databricks-side VPC registration (databricks_mws_networks) — the BYO-VPC entry point of the three-piece split. Carries the base/privatelink keyed registration semantics out of aws-account-network-vpc verbatim (in-place PL cutover: base retained, "-privatelink" added; nothing deleted while attached). Inputs are caller-supplied IDs (vpc/subnets/SG), so it registers your own VPC or the aws-account-vpc module's outputs.
- Plan tests with mock_provider covering the keying, the PL-variant naming, and the endpoint-value independence.
