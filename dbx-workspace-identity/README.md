# dbx-workspace-identity

Assigns account-level principals (groups, service principals, users) to a Databricks workspace with workspace roles (USER or ADMIN) via `databricks_mws_permission_assignment`.

## What this module abstracts

"The identities that can access this workspace and their roles" — one indivisible function. The module takes pre-existing account-level principal IDs and registers them against a target workspace. It does NOT create groups, users, or service principals; it manages references only.

This separation of concerns aligns with DATABRICKS_RULES.md Rule 3.3: in SCIM or AIM deployments, the IdP owns group/user creation; this module wires those identities into a workspace.

## When to use

- You have created a workspace (via a workspace creation module or the Databricks UI/API) and want to grant account principals access.
- You are bootstrapping a new workspace and need to assign one or more account groups as workspace admins or users.
- You manage workspace access alongside workspace creation in the same Terraform configuration.

## When NOT to use

- You need to CREATE groups, users, or service principals — use `databricks_group`, `databricks_user`, or `databricks_service_principal` directly (or a dedicated identity module) at the root composition.
- You need to manage workspace-level permissions on specific objects (tables, clusters, notebooks) — use `databricks_permissions` or `databricks_grants` in a workspace-surface module.
- You are on the workspace provider surface and want to set workspace-level role grants — `databricks_mws_permission_assignment` requires the account provider surface.

## Minimum platform tier

**Premium.** `databricks_mws_permission_assignment` is a Premium-tier account API. Applying this module against a Standard-tier workspace will fail at apply time with an API error. The Databricks Terraform provider does not check tier at plan time. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Identity model

This module manages **references** to pre-existing account-level principals. It supports all identity models:

- **Native**: Pass principal IDs created by `databricks_group` / `databricks_user` / `databricks_service_principal`.
- **SCIM/AIM**: Pass principal IDs sourced from `data "databricks_group"` or `data "databricks_user"` lookups. The module sets `ignore_changes = [principal_id]` per DATABRICKS_RULES.md Rule 3.2 to avoid plan noise when the IdP syncs and resolves IDs.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account-level API:

| Deployment | Account host |
|---|---|
| Commercial | `https://accounts.cloud.databricks.com` |
| GovCloud civilian | `https://accounts.cloud.databricks.us` |
| GovCloud DoD | `https://accounts-dod.cloud.databricks.mil` |

This module does NOT use a workspace-level provider. `databricks_mws_permission_assignment` is an account API.

## Race condition handled

The module includes a `time_sleep` resource (20s) before `databricks_mws_permission_assignment` resources are created. The workspace permission assignment API can return 404 for approximately 20 seconds after a workspace becomes operational. The delay is a sanctioned use of `time_sleep` per DATABRICKS_RULES.md Rule 3.1.

If you are assigning principals to an already-running workspace (not freshly created in the same apply), the 20s delay is harmless but unavoidable with the current `time_sleep` approach.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.14 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | >= 1.14 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.9 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_mws_permission_assignment.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_permission_assignment) | resource |
| [time_sleep.workspace_api_ready](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_assignments"></a> [assignments](#input\_assignments) | Map of workspace permission assignments. Each key is a human-readable label (used as the for\_each key).<br/>Each value contains:<br/>  - principal\_id: Databricks account-level principal ID (group, service principal, or user).<br/>  - roles: List of workspace roles to assign. Valid values are "USER" and "ADMIN".<br/>Example:<br/>  {<br/>    data\_eng\_group = { principal\_id = 123456789, roles = ["USER"] }<br/>    workspace\_admin = { principal\_id = 987654321, roles = ["ADMIN"] }<br/>  } | <pre>map(object({<br/>    principal_id = number<br/>    roles        = list(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_workspace_id"></a> [workspace\_id](#input\_workspace\_id) | Databricks workspace ID to assign principals to. Obtained from the workspace creation module or a data source. | `number` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_assignment_ids"></a> [assignment\_ids](#output\_assignment\_ids) | Map of assignment label to the Databricks permission assignment ID. Keyed by the same keys as the assignments input variable. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid assignments produce the expected `databricks_mws_permission_assignment` resources.
- Empty roles list is rejected by variable validation.
- Invalid role values are rejected by variable validation.
- `assignment_ids` output is keyed consistently with the `assignments` input.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks account) verifies actual permission assignment creation. It is credential-gated and skipped until a test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
