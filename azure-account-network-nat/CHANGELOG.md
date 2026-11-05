# Changelog

All notable changes to the `azure-account-network-nat` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.0] - 2026-11-05

### Added
- Initial module: Standard NAT gateway + static public IP + subnet associations (MAP-keyed `subnets` input — the for_each-over-computed-list trap is designed out), closing the blueprint-gaps N2 High finding (azure classic had no egress resource while `no_public_ip` defaults to true — clusters had no internet path). Azurerm-4.x argument (`public_ip_address_id`) used; no route table needed (subnet NAT association installs the default system route).
- Outputs `nat_gateway_id`, `nat_gateway_name`, `public_ip_id`, `public_ip_address`.
- `examples/basic`, `tests/plan.tftest.hcl` (9 plan runs incl. variable validations).
- UNVERIFIED-live: plan-verified only; the NAT egress path has not been exercised on a real deployment.
