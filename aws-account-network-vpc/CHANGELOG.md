# Changelog

All notable changes to the `aws-account-network-vpc` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.3.0] - 2026-09-29

### Changed
- **Back-end PrivateLink on a running workspace is now a clean single apply: RETAIN the old network config instead of replacing (deleting) it.** `databricks_mws_networks` is now keyed by role via `for_each` (`base`, and `privatelink` when `vpc_endpoint_ids` are set) instead of a single unkeyed registration. Enabling PrivateLink **adds** the `privatelink` registration and **keeps** `base`; the caller repoints the workspace's `network_id` in place (running-update allowlist). The module derives the PrivateLink registration name as `<network_name>-privatelink`, so callers no longer need to vary `network_name` themselves.
- **Removed `create_before_destroy`** from `databricks_mws_networks`. It is no longer needed: nothing is replaced or deleted while attached, so the v0.2.0 failure mode (`cannot delete a network while it is attached to a workspace`, hit again live 2026-09-28) cannot occur. This supersedes the v0.2.0 fix, which treated the operation as a force-replace.

  Rationale: `databricks_mws_networks` is replace-only for `vpc_endpoints` (provider Update is a no-op; network configs are immutable). Databricks' documented procedure for adding PrivateLink to a running workspace ("Update a running workspace") is *create a new network config → repoint the workspace* — with **no step to delete the old config**, no documented limit on network configs, and unattached configs being metadata-only and free. Databricks explicitly allows multiple network config objects on the same VPC/subnets (docs: customer-managed VPC).

### Migration
- A `moved` block migrates existing state (`databricks_mws_networks.this` → `databricks_mws_networks.this["base"]`) with no destroy/create. Verify a plan against an existing deployment shows the move, not a replacement, before applying.

### Notes
- After a PrivateLink cutover, one detached `base` network config lingers (≤1 per workspace). It is harmless; the new `network_ids` output surfaces both IDs so it can be deleted deliberately later (safe once no workspace references it).
- New output `network_ids` (map of role → network ID); `databricks_network_id` now resolves to the active config (PrivateLink when enabled, else base).
- `network_name` is now capped at 88 chars (was 100) to leave room for the derived `-privatelink` suffix.

## [0.2.0] - 2026-08-03

### Fixed
- **`create_before_destroy` on `databricks_mws_networks` — enables in-place back-end PrivateLink adoption on a LIVE workspace.** The `vpc_endpoints` block is ForceNew, so adopting PrivateLink replaces the network *registration*; without `create_before_destroy` Terraform tried delete-then-create and the delete failed with `cannot delete mws networks: INVALID_STATE: Network is being used by active workspace`. Creating the replacement first lets the workspace re-point `network_id` (which is in the `mws_workspaces` running-update allowlist) before the old registration is removed. **The VPC does not change** — PrivateLink adds interface endpoints to the existing VPC; only this metadata-only registration is re-created. Found by a live evolution-journey apply; the pattern existed in the prior-art stack and was dropped in this module. Callers must also vary `network_name` when PrivateLink is toggled so the create-before-destroy replacement doesn't collide (see `networking/aws/basic` v0.3.2).

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates AWS VPC, private/public/PrivateLink subnets, route tables, Databricks-required security group, and `databricks_mws_networks` registration.
- GovCloud parameterization via `databricks_gov_shard` input (commercial, civilian, dod) per DATABRICKS_RULES.md Rule 1.5.
- Optional public subnets via `public_subnet_cidrs` (for NAT gateway use with aws-account-network-egress-internet).
- Optional PrivateLink-dedicated subnets via `privatelink_subnet_cidrs` (for use with aws-account-network-privatelink-endpoints).
- Optional PrivateLink wiring via `vpc_endpoint_ids` input — conditionally includes `vpc_endpoints` block in `databricks_mws_networks`.
- Per-private-subnet route tables exposed via `private_route_table_ids` output for downstream egress and VPC endpoint modules.
- Variable validation on `databricks_gov_shard`, `resource_prefix` (length + charset), `vpc_cidr` (valid CIDR), `private_subnet_cidrs` (minimum 2), `public_subnet_cidrs` (valid CIDRs), `privatelink_subnet_cidrs` (valid CIDRs), `azs` (minimum 2, AZ name format), `network_name` (length + charset).
- Outputs: `vpc_id`, `private_subnet_ids`, `public_subnet_ids`, `privatelink_subnet_ids`, `security_group_id`, `databricks_network_id`, `private_route_table_ids`, `vpc_cidr`.
- `examples/basic/` — minimum invocation against commercial AWS with two private subnets.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations, resource attribute checks, and PrivateLink conditional logic.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS + Databricks (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).
