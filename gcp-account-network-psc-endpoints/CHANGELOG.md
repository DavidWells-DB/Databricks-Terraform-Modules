# Changelog

All notable changes to the `gcp-account-network-psc-endpoints` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [v0.1.2] - 2026-11-05

### Added - N4 allowlist readback
- `allowed_vpc_endpoint_ids` output: the EFFECTIVE list on the PAS object (empty unless private_access_level = ENDPOINT) — the readback oracle for the blueprint-level pass-through (WebUI gap report N4).


## [0.1.1] - 2026-11-04

### Fixed — external review finding (Med): deprecated resource-level account_id
- Removed `account_id` from `databricks_mws_private_access_settings` (deprecated; the account is configured on the provider). The two `databricks_mws_vpc_endpoint` resources KEEP their explicit `account_id` deliberately — the provider does not propagate the provider-level account to that resource (live 2026-08-03 empty-account-path bug).


## [0.1.0] - 2026-06-23

### Added
- Initial module: creates GCP PSC compute addresses, forwarding rules, private DNS zone (`gcp.databricks.com`), DNS record sets, and registers endpoints via `databricks_mws_vpc_endpoint` (workspace + relay) and `databricks_mws_private_access_settings`.
- Static locals map of Databricks PSC service attachment URIs for all 15 supported GCP regions (workspace plproxy + SCC relay ngrok); source: https://docs.databricks.com/gcp/en/resources/ip-domain-region#psc.
- Optional override inputs `workspace_psc_service_attachment` and `relay_psc_service_attachment` for callers that need to pin a specific URI.
- Variable validation on `region` (enumerated supported values), `resource_prefix` (GCP naming constraints), and `private_access_level` (ACCOUNT or ENDPOINT).
- Outputs: `workspace_psc_endpoint_id`, `relay_psc_endpoint_id`, `private_access_settings_id`, `workspace_psc_ip`, `relay_psc_ip`, `workspace_psc_forwarding_rule_id`, `relay_psc_forwarding_rule_id`, `dns_zone_name`, `workspace_psc_service_attachment`, `relay_psc_service_attachment`.
- `examples/basic/` — minimum invocation against a GCP project with us-central1.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering region URI resolution, variable validations, service attachment overrides, and resource attribute checks.
- `tests/integration.tftest.hcl` — apply-command stub for live GCP + Databricks (credential-gated; includes a placeholder for the tier-failure case per the Databricks module rules Rule 4.1).
