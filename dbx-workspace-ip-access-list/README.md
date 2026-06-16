# dbx-workspace-ip-access-list

Enables IP-based network access control for a Databricks workspace. The module activates IP access list enforcement via `databricks_workspace_conf` and creates one ALLOW list (required) and an optional BLOCK list via `databricks_ip_access_list`.

## What this module abstracts

"IP access list enforcement for a workspace" — one indivisible function. The `databricks_workspace_conf` activation flag and the `databricks_ip_access_list` resources form an inseparable pair: creating lists without enabling the flag leaves the workspace unprotected. This module ensures both are always provisioned together.

## When to use

- You want to restrict which IP addresses or CIDR ranges can reach a Databricks workspace.
- You need an allow list (required), with an optional explicit block list that takes precedence over the allow list.
- The workspace is Premium or Enterprise tier (see Minimum platform tier below).

## When NOT to use

- You only need account-level IP restrictions — use Databricks account console settings instead.
- Your workspace is Standard tier — IP access lists are a Premium/Enterprise feature.
- You need to manage many distinct named lists separately — extend this module or manage `databricks_ip_access_list` resources directly in the root composition.

## Minimum platform tier

**Premium** (all clouds). The `databricks_ip_access_list` resource and the `enableIpAccessLists` workspace conf flag are gated on Premium or Enterprise tier. Applying this module against a Standard-tier workspace will fail at apply time with an API error. The Databricks Terraform provider does not check tier at plan time.

Per DATABRICKS_RULES.md Rule 2.3 and Rule 4.1: the `tests/integration.tftest.hcl` file includes a stub for the tier-failure case; enable it once a Standard-tier test workspace is provisioned.

## Provider configuration

This module is **workspace-scoped** (`databricks.workspace` surface only). It declares `configuration_aliases = [databricks.workspace]` per DATABRICKS_RULES.md Rule 2.2. The caller must supply a `databricks.workspace` provider configured against the target workspace host URL.

No AWS, Azure, or GCP provider is required — this module is cloud-agnostic.

## Block list behaviour

The block list is optional (`block_list_cidrs = null` by default). When provided, Databricks evaluates the BLOCK list before the ALLOW list — a CIDR present in both lists is denied access.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.39 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.workspace"></a> [databricks.workspace](#provider\_databricks.workspace) | >= 1.39 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_ip_access_list.allow](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/ip_access_list) | resource |
| [databricks_ip_access_list.block](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/ip_access_list) | resource |
| [databricks_workspace_conf.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/workspace_conf) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allow_list_cidrs"></a> [allow\_list\_cidrs](#input\_allow\_list\_cidrs) | List of IPv4 CIDR blocks or individual IP addresses permitted to reach the workspace. At least one entry is required. Example: ["10.0.0.0/8", "203.0.113.42"]. | `list(string)` | n/a | yes |
| <a name="input_allow_list_label"></a> [allow\_list\_label](#input\_allow\_list\_label) | Human-readable label for the ALLOW IP access list entry. Displayed in the Databricks workspace security settings UI. | `string` | `"allow-list"` | no |
| <a name="input_block_list_cidrs"></a> [block\_list\_cidrs](#input\_block\_list\_cidrs) | Optional list of IPv4 CIDR blocks or individual IP addresses explicitly denied workspace access. Entries in the block list take precedence over the allow list. null or empty list means no block list is created. | `list(string)` | `null` | no |
| <a name="input_block_list_label"></a> [block\_list\_label](#input\_block\_list\_label) | Human-readable label for the BLOCK IP access list entry. Only used when block\_list\_cidrs is non-null. | `string` | `"block-list"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_allow_list_id"></a> [allow\_list\_id](#output\_allow\_list\_id) | Databricks IP access list ID for the ALLOW list. Use this to reference the list in downstream tooling or for audit purposes. |
| <a name="output_allow_list_label"></a> [allow\_list\_label](#output\_allow\_list\_label) | Label of the ALLOW IP access list as registered in Databricks. |
| <a name="output_block_list_id"></a> [block\_list\_id](#output\_block\_list\_id) | Databricks IP access list ID for the BLOCK list. null when no block list was configured. |
| <a name="output_workspace_conf_id"></a> [workspace\_conf\_id](#output\_workspace\_conf\_id) | ID of the databricks\_workspace\_conf resource that enabled IP access list enforcement. Useful for expressing explicit dependencies in consuming configurations. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Allow list is planned with the correct CIDR list and label
- Block list resource is created when `block_list_cidrs` is non-null, absent when null
- Empty `allow_list_cidrs` is rejected by variable validation
- Invalid CIDR format is rejected by variable validation
- Empty `block_list_cidrs` list (as opposed to null) is rejected by variable validation
- Label length validation bounds

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks workspace) verifies actual list creation and enforcement activation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1). The integration test includes a tier-failure stub.
