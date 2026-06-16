# aws-account-workspace

Creates a classic-compute Databricks workspace on AWS by wiring together pre-created credentials, storage, and network configurations. Optionally attaches PrivateLink settings, customer-managed keys (CMK), and a network connectivity configuration (NCC).

## What this module abstracts

"The Databricks workspace" — the central resource in any workspace deployment. This module wires the four required registrations (credentials, storage, network, and workspace) into a single resource, handles DNS propagation via a sanctioned `time_sleep`, and optionally binds an NCC for serverless or Databricks-managed egress. Pairing the workspace registration with its DNS readiness logic is an indivisible function; separating them would produce a thin wrapper that doesn't raise the level of abstraction.

## When to use

- You are provisioning a new AWS-hosted Databricks workspace (commercial, GovCloud civilian, or GovCloud DoD).
- You have already created (or will create) credentials, storage, and network configurations using the paired modules:
  - `aws-account-workspace-credentials` — produces `credentials_id`
  - `aws-account-workspace-storage` — produces `storage_configuration_id`
  - `aws-account-network` or `aws-account-network-vpc` — produces `databricks_network_id`
- You want a single module call that creates the workspace and blocks until DNS propagates.

## When NOT to use

- You are creating a serverless-only workspace (no customer VPC, no DBFS root) — use `aws-account-workspace-serverless` instead.
- You are on Azure or GCP — they use cloud-specific workspace resources and provider arguments.
- You want to configure things inside the workspace (grants, clusters, jobs) — that is a workspace-scoped concern handled by workspace-side modules, which require this module's `workspace_url` output as their provider `host`.

## Minimum platform tier

**Premium.** Creating a workspace via `databricks_mws_workspaces` requires a Premium-or-above Databricks account. Applying against a Standard-tier account will fail at the Databricks API (the provider performs no plan-time tier check). PrivateLink (`private_access_settings_id`) and the Compliance Security Profile (auto-enabled on GovCloud) require **Enterprise**. See DATABRICKS_RULES.md Rules 2.3 and 4.1.

## GovCloud parameterization

The `databricks_gov_shard` input drives computed locals for the Databricks account host URL. All variance is expressed through inputs and locals — the module does not branch at the resource level.

| Shard | `databricks_gov_shard` | Databricks account host |
|---|---|---|
| Commercial | `null` (default) | `https://accounts.cloud.databricks.com` |
| GovCloud civilian | `"civilian"` | `https://accounts.cloud.databricks.us` |
| GovCloud DoD | `"dod"` | `https://accounts-dod.cloud.databricks.mil` |

Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud

GovCloud workspaces have the Compliance Security Profile auto-enabled at the cloud level (not a tier decision). Nitro instance types are required for GovCloud compute.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account host matching the `databricks_gov_shard` value:

- Commercial: `host = "https://accounts.cloud.databricks.com"`
- GovCloud civilian: `host = "https://accounts.cloud.databricks.us"`
- GovCloud DoD: `host = "https://accounts-dod.cloud.databricks.mil"`

No AWS provider is required by this module — AWS resources are managed by the paired credentials, storage, and network modules.

## Race conditions handled

The module includes a `time_sleep` resource (30s) after workspace creation for DNS propagation. The `workspace_url` returned by `databricks_mws_workspaces` is not immediately resolvable — downstream workspace providers that use `workspace_url` as their `host` must wait for this propagation. The `dns_propagation_complete` output triggers implicitly when this sleep completes, making it safe to use as a dependency signal in root compositions. The delay is a sanctioned use of `time_sleep` per DATABRICKS_RULES.md Rule 3.1.

## Ignored lifecycle changes

`custom_tags` is set to `ignore_changes` because tags may be modified outside Terraform via the Databricks account console or UI. This follows DATABRICKS_RULES.md Rule 3.2.

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
| [databricks_mws_ncc_binding.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_ncc_binding) | resource |
| [databricks_mws_workspaces.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_workspaces) | resource |
| [time_sleep.dns_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_credentials_id"></a> [credentials\_id](#input\_credentials\_id) | Databricks credentials object ID produced by the aws-account-workspace-credentials module. Grants the control plane permission to manage compute in the customer AWS account. | `string` | n/a | yes |
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags) | Tags propagated to workspace-related cloud resources by the Databricks control plane. | `map(string)` | `{}` | no |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Used to scope the workspace within the account. | `string` | n/a | yes |
| <a name="input_databricks_gov_shard"></a> [databricks\_gov\_shard](#input\_databricks\_gov\_shard) | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. | `string` | `null` | no |
| <a name="input_databricks_network_id"></a> [databricks\_network\_id](#input\_databricks\_network\_id) | Databricks network configuration ID produced by the aws-account-network module. Identifies the VPC and subnets in which workspace compute runs. | `string` | n/a | yes |
| <a name="input_managed_services_key_id"></a> [managed\_services\_key\_id](#input\_managed\_services\_key\_id) | Databricks CMK configuration ID for managed services (notebooks, secrets) encryption. null uses the Databricks-managed key. | `string` | `null` | no |
| <a name="input_network_connectivity_config_id"></a> [network\_connectivity\_config\_id](#input\_network\_connectivity\_config\_id) | Databricks network connectivity configuration (NCC) ID. When set, binds the NCC to this workspace for serverless or Databricks-managed network egress. null skips NCC binding. | `string` | `null` | no |
| <a name="input_private_access_settings_id"></a> [private\_access\_settings\_id](#input\_private\_access\_settings\_id) | Databricks private access settings ID. When set, enables PrivateLink for the workspace. Produced by the aws-account-network-privatelink module. null disables PrivateLink. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region in which the workspace is deployed (e.g. "us-east-1"). | `string` | n/a | yes |
| <a name="input_storage_configuration_id"></a> [storage\_configuration\_id](#input\_storage\_configuration\_id) | Databricks storage configuration ID produced by the aws-account-workspace-storage module. Identifies the S3 bucket used as the workspace's DBFS root. | `string` | n/a | yes |
| <a name="input_workspace_name"></a> [workspace\_name](#input\_workspace\_name) | Human-readable name of the Databricks workspace. Must be unique within the Databricks account. | `string` | n/a | yes |
| <a name="input_workspace_storage_key_id"></a> [workspace\_storage\_key\_id](#input\_workspace\_storage\_key\_id) | Databricks CMK configuration ID for workspace storage (DBFS root) encryption. null uses the Databricks-managed key. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_databricks_host"></a> [databricks\_host](#output\_databricks\_host) | Databricks account host URL computed from databricks\_gov\_shard. Useful for verification and for configuring downstream provider instances. |
| <a name="output_deployment_name"></a> [deployment\_name](#output\_deployment\_name) | Deployment name portion of the workspace URL subdomain. Useful for constructing workspace-specific resource names. |
| <a name="output_dns_propagation_complete"></a> [dns\_propagation\_complete](#output\_dns\_propagation\_complete) | Opaque value that becomes available only after the DNS propagation sleep completes. Use this output as an implicit depends\_on trigger in root compositions that configure workspace-scoped providers. |
| <a name="output_workspace_host"></a> [workspace\_host](#output\_workspace\_host) | Alias for workspace\_url. Provided for callers that prefer the 'host' naming convention when configuring the workspace Databricks provider. |
| <a name="output_workspace_id"></a> [workspace\_id](#output\_workspace\_id) | Databricks workspace ID (numeric). Used by workspace-scoped modules and data sources that require a workspace ID. |
| <a name="output_workspace_url"></a> [workspace\_url](#output\_workspace\_url) | Full URL of the Databricks workspace (e.g. https://adb-<id>.azuredatabricks.net). Use as the host for the workspace-scoped Databricks provider after DNS propagation. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each `databricks_gov_shard` value (null, civilian, dod) produces the correct account host URL
- Invalid `databricks_gov_shard` is rejected by variable validation
- Invalid `workspace_name` patterns are rejected by variable validation
- Invalid `region` patterns are rejected by variable validation
- Workspace resource is planned with expected attributes
- NCC binding resource is conditionally created when `network_connectivity_config_id` is set
- NCC binding resource is NOT created when `network_connectivity_config_id` is null

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks account with Premium tier) verifies actual workspace creation and DNS propagation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
