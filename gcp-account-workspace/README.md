# gcp-account-workspace

Creates a classic-compute Databricks workspace on GCP, wiring pre-created network and storage configurations with optional Private Service Connect (PSC) and optional CMEK.

## What this module abstracts

"The Databricks workspace on GCP" — one indivisible deployment unit. The `databricks_mws_workspaces` resource wires together the GCP project, network configuration, storage configuration, and optional PSC/CMEK into a running workspace. A DNS propagation delay is included to ensure downstream workspace-scoped providers can connect immediately after this module completes.

## When to use

- You are provisioning a new GCP-hosted classic-compute Databricks workspace.
- You have already created a network configuration (via `gcp-account-network-vpc`) and a storage configuration (via `gcp-account-workspace-storage`) and want to combine them into a running workspace.
- You want a single module that creates the workspace AND gates downstream configuration on DNS propagation.

## When NOT to use

- You want a serverless-only workspace with no classic compute plane — use `gcp-account-workspace-serverless` instead.
- You are on AWS or Azure — use `aws-account-workspace` or `azure-account-workspace` respectively.
- You need to reference an existing workspace without creating one — use a `data "databricks_mws_workspaces"` source at the root composition.

## Minimum platform tier

**Premium.** `databricks_mws_workspaces` is an account-level resource available only on Premium and above. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks GCP account host (`https://accounts.gcp.databricks.com`).

No GCP provider is required in this module — all GCP-side resources are pre-created and passed as IDs. Only the Databricks account API is called.

## DNS propagation

The module includes a `time_sleep` resource (30s) after workspace creation. Without this delay, the workspace URL returned by the Databricks API is not yet DNS-resolvable. Downstream workspace-scoped providers that use `workspace_url` as their `host` must wait for this propagation. Use the `dns_propagation_complete` output as an implicit `depends_on` trigger in root compositions.

This is a sanctioned use of `time_sleep` per DATABRICKS_RULES.md Rule 3.1.

## CMEK

Pass pre-registered Databricks CMK configuration IDs to `managed_services_key_id` and `workspace_storage_key_id`. CMK keys and their Databricks registrations are created by a separate encryption-keys module (not yet built for GCP) and their IDs passed here as inputs.

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
| <a name="input_databricks_network_id"></a> [databricks\_network\_id](#input\_databricks\_network\_id) | Databricks network configuration ID produced by the gcp-account-network-vpc module. Identifies the VPC and subnetwork in which workspace compute runs. | `string` | n/a | yes |
| <a name="input_managed_services_key_id"></a> [managed\_services\_key\_id](#input\_managed\_services\_key\_id) | Databricks CMK configuration ID for managed services (notebooks, secrets) encryption. null uses the Databricks-managed key. | `string` | `null` | no |
| <a name="input_private_access_settings_id"></a> [private\_access\_settings\_id](#input\_private\_access\_settings\_id) | Databricks private access settings ID. When set, enables PSC (Private Service Connect) for the workspace. Produced by the gcp-account-network-psc-endpoints module. null disables PSC. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID in which the workspace data plane runs. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the workspace data plane (e.g. "us-central1"). Must match the region of the network and storage configurations. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix used to derive the workspace deployment name. Must be 1-20 characters, lowercase letters, digits, or hyphens, starting with a letter. | `string` | n/a | yes |
| <a name="input_storage_configuration_id"></a> [storage\_configuration\_id](#input\_storage\_configuration\_id) | Databricks storage configuration ID produced by the gcp-account-workspace-storage module. Identifies the GCS bucket used as the workspace's root storage. | `string` | n/a | yes |
| <a name="input_workspace_name"></a> [workspace\_name](#input\_workspace\_name) | Human-readable name of the Databricks workspace. Must be unique within the Databricks account. | `string` | n/a | yes |
| <a name="input_workspace_storage_key_id"></a> [workspace\_storage\_key\_id](#input\_workspace\_storage\_key\_id) | Databricks CMK configuration ID for workspace storage (root GCS bucket) encryption. null uses the Databricks-managed key. | `string` | `null` | no |

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
- `workspace_name` validation rejects names that are too short, too long, or contain invalid characters
- `project_id` validation rejects invalid GCP project ID formats
- `region` validation rejects invalid GCP region formats
- `resource_prefix` validation rejects invalid prefixes
- `databricks_account_id` validation rejects non-UUID values
- Workspace resource uses correct `workspace_name`, `location`, and `project_id`
- DNS propagation `time_sleep` depends on workspace creation

Run with `terraform test` from the module root.

An apply-command integration test (against a real GCP project + Databricks account) verifies actual workspace creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
