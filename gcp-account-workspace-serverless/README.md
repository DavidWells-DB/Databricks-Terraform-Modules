# gcp-account-workspace-serverless

Creates a serverless-only Databricks workspace on GCP. No VPC, no GKE node pool, no classic compute plane is required or configured — Databricks manages all compute infrastructure on your behalf.

## What this module abstracts

"A Databricks workspace whose compute is entirely Databricks-managed (serverless)." Setting `compute_mode = "SERVERLESS"` on `databricks_mws_workspaces` is the key distinction from the classic `gcp-account-workspace` module. This module omits the network configuration, storage configuration, and GKE config blocks that are required for classic workspaces — they are invalid in serverless mode. The result is the smallest possible GCP workspace footprint: one `databricks_mws_workspaces` resource pointed at a GCP project, with Databricks owning all compute infrastructure.

## When to use

- You want Databricks Serverless compute on GCP (SQL Warehouses, Serverless Jobs, Model Serving) without managing a customer VPC or GKE node pool.
- You want the fastest path to a running GCP Databricks workspace with the lowest operational overhead.
- You are building a net-new GCP workspace and do not need to run classic compute (interactive clusters, classic jobs).

## When NOT to use

- You need classic compute (interactive clusters, instance pools, cluster policies) — use `gcp-account-workspace` instead, which wires in VPC, storage, and GKE configuration.
- You already have a `databricks_mws_workspaces` resource in state — use a `moved` block to adopt it rather than re-creating via this module.
- You need PSC (Private Service Connect) or CMK for workspace storage — serverless workspaces on GCP do not support these configurations; only `managed_services_key_id` (for notebook/secret encryption) is supported.

## Minimum platform tier

**Premium.** Serverless compute is a Premium-tier feature on Databricks. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject and apply will fail. See DATABRICKS_RULES.md Rules 2.3 and 4.1.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the GCP Databricks account host: `https://accounts.gcp.databricks.com`.

No `google` provider is required — this module creates only the Databricks workspace registration. GCP-side prerequisites (service account, IAM bindings) are handled by the `gcp-account-provisioning-service-account` module, which must be run before this module.

## DNS propagation

The module includes a `time_sleep` resource (30s) after workspace creation. The `workspace_url` returned by `databricks_mws_workspaces` is not immediately DNS-resolvable. The `dns_propagation_complete` output can be used as an implicit `depends_on` trigger for root compositions that configure workspace-scoped Databricks providers after this module runs.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.50 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | >= 1.50 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.9 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_mws_workspaces.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_workspaces) | resource |
| [time_sleep.dns_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags) | Tags propagated to workspace-related GCP resources by the Databricks control plane. | `map(string)` | `{}` | no |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Used to scope the workspace within the account. | `string` | n/a | yes |
| <a name="input_managed_services_key_id"></a> [managed\_services\_key\_id](#input\_managed\_services\_key\_id) | Databricks CMK configuration ID for managed services (notebooks, secrets) encryption. null uses the Databricks-managed key. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID in which the serverless workspace is created. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the workspace (e.g. "us-central1"). Serverless compute runs in Databricks-managed infrastructure in this region. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix used to derive the workspace deployment name. Must be 1-20 characters, lowercase letters, digits, or hyphens, starting with a letter. | `string` | n/a | yes |
| <a name="input_workspace_name"></a> [workspace\_name](#input\_workspace\_name) | Human-readable name of the Databricks workspace. Must be unique within the Databricks account. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_deployment_name"></a> [deployment\_name](#output\_deployment\_name) | Deployment name portion of the workspace URL subdomain. Useful for constructing workspace-specific resource names. |
| <a name="output_dns_propagation_complete"></a> [dns\_propagation\_complete](#output\_dns\_propagation\_complete) | Opaque value that becomes available only after the DNS propagation sleep completes. Use this output as an implicit depends\_on trigger in root compositions that configure workspace-scoped providers. |
| <a name="output_workspace_host"></a> [workspace\_host](#output\_workspace\_host) | Alias for workspace\_url. Provided for callers that prefer the 'host' naming convention when configuring the workspace Databricks provider. |
| <a name="output_workspace_id"></a> [workspace\_id](#output\_workspace\_id) | Databricks workspace ID (numeric). Used by workspace-scoped modules and data sources that require a workspace ID. |
| <a name="output_workspace_url"></a> [workspace\_url](#output\_workspace\_url) | Full URL of the Databricks workspace (e.g. https://<id>.gcp.databricks.com). Use as the host for the workspace-scoped Databricks provider after DNS propagation. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid inputs produce expected resource attributes (`workspace_name`, `deployment_name`, `compute_mode`)
- Invalid `databricks_account_id` (non-UUID) is rejected by variable validation
- Invalid `project_id` format is rejected by variable validation
- Invalid `region` format is rejected by variable validation
- Invalid `resource_prefix` format is rejected by variable validation
- Invalid `workspace_name` (too short, bad chars) is rejected by variable validation

Run with `terraform test` from the module root.

An apply-command integration test (against a real GCP project + Databricks account) verifies actual workspace creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
