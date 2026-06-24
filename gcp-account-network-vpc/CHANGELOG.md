# Changelog

All notable changes to the `gcp-account-network-vpc` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates GCP VPC (`google_compute_network`), subnetwork with secondary IP ranges (`google_compute_subnetwork`), Databricks-required ingress firewall rule (`google_compute_firewall`), and registers the network with Databricks via `databricks_mws_networks`.
- Variable validation on `project_id` (GCP format), `region` (GCP region format), `resource_prefix` (1-20 chars, lowercase), `network_cidr` (valid IPv4 CIDR, /9-/29 bounds), `pod_secondary_range_cidr`, `service_secondary_range_cidr`, `network_name` (conservative bounds), `databricks_account_id` (UUID format).
- Secondary IP ranges for GKE pod and service networking; range names exposed as outputs.
- Optional PSC wiring via `vpc_endpoint_ids` input — passes endpoint IDs into the `databricks_mws_networks` `vpc_endpoints` block when provided.
- Outputs: `network_self_link`, `network_name`, `subnetwork_self_link`, `subnetwork_name`, `databricks_network_id`, `pod_secondary_range_name`, `service_secondary_range_name`, `network_cidr`.
- `examples/basic/` — minimum invocation against a GCP project.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations, resource attribute checks, and PSC conditional logic.
- `tests/integration.tftest.hcl` — apply-command stub for live GCP + Databricks (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).
