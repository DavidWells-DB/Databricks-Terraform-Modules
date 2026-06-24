# Changelog

All notable changes to the `dbx-workspace-cluster-policies` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates `databricks_cluster_policy` resources via `for_each` and assigns `databricks_permissions` (CAN_USE) per policy.
- Support for both custom `definition` (Policy Definition Language JSON) and policy-family inheritance (`policy_family_id` + `policy_family_definition_overrides`).
- Variable validation enforcing mutual exclusivity of `definition` vs `policy_family_id`, overrides only with family ID, `max_clusters_per_user > 0`, and policy name length bounds (1-100 chars).
- `policy_assignments` variable accepting per-policy access control lists with group, user, or service principal targets.
- Validation that each access_control entry sets exactly one principal selector.
- Outputs: `policy_ids`, `policy_policy_ids`, `policy_names`.
- `examples/basic/` — minimum invocation demonstrating both definition and policy-family approaches with permissions.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and resource attribute assertions.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks workspace (credential-gated; includes placeholder for tier-failure case per DATABRICKS_RULES Rule 4.1).
