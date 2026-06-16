# aws-account-workspace-serverless

Creates a serverless-only Databricks workspace on AWS. No classic compute plane, no customer VPC, no IAM cross-account credentials, and no DBFS storage configuration are required or permitted — Databricks manages all infrastructure on the serverless control plane.

## What this module abstracts

"A serverless Databricks workspace" — a distinct provisioning mode from the classic workspace. The only required inputs are a workspace name, an AWS region, and a Databricks account ID. Everything else (compute, networking, storage) is managed by Databricks.

Optionally wires a Customer-Managed Key (managed-services only) and an NCC binding for serverless private connectivity.

## When to use

- You want a Databricks workspace backed entirely by the serverless compute plane (no VPC management, no IAM cross-account role).
- You want the simplest possible workspace deployment path on AWS.
- You need serverless SQL warehouses, serverless jobs, or model serving without standing up a classic compute plane.

## When NOT to use

- You need classic interactive clusters or classic job clusters — use `aws-account-workspace` (classic compute plane) instead.
- You are on Azure or GCP — those platforms have their own workspace modules.
- You need a workspace with a customer-managed VPC (VPC injection) — serverless workspaces do not support VPC injection.

## Minimum platform tier

**Premium.** The Databricks Terraform provider does not check tier at plan time; applying against a Standard-tier account will result in an API rejection at apply time. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## GovCloud parameterization

The `databricks_gov_shard` input drives the computed Databricks account console host:

| Shard | `databricks_gov_shard` | Account host |
|---|---|---|
| Commercial | `null` (default) | `https://accounts.cloud.databricks.com` |
| GovCloud civilian | `"civilian"` | `https://accounts.cloud.databricks.us` |
| GovCloud DoD | `"dod"` | `https://accounts-dod.cloud.databricks.mil` |

Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud

The `databricks_account_host` output exposes the computed value for use in root compositions.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account host appropriate for the shard.

No AWS provider is required — serverless workspaces do not create any AWS-side resources.

## Optional features

- **Managed-services CMK** (`managed_services_key_id`): ID of a `databricks_mws_customer_managed_keys` object with `use_cases = ["MANAGED_SERVICES"]`. Encrypts notebooks and secrets in the control plane.
- **NCC binding** (`network_connectivity_config_id`): Binds a Network Connectivity Config to the workspace for serverless private connectivity to customer data sources. Creates a `databricks_mws_ncc_binding` resource.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.50 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | >= 1.50 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_mws_ncc_binding.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_ncc_binding) | resource |
| [databricks_mws_workspaces.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_workspaces) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags) | Optional. Key-value tags applied to clusters launched in this workspace. Note: tags set here may be overridden by humans in the Databricks UI; this field is ignored on plan after initial creation (see lifecycle ignore\_changes comment in main.tf). | `map(string)` | `{}` | no |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Must match the account\_id used by the databricks.account provider. | `string` | n/a | yes |
| <a name="input_databricks_gov_shard"></a> [databricks\_gov\_shard](#input\_databricks\_gov\_shard) | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. | `string` | `null` | no |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | Optional. URL prefix component for the workspace host (e.g. "my-ws" produces "my-ws.cloud.databricks.com"). Leave null to let Databricks auto-assign. | `string` | `null` | no |
| <a name="input_managed_services_key_id"></a> [managed\_services\_key\_id](#input\_managed\_services\_key\_id) | Optional. Databricks customer-managed key ID (from databricks\_mws\_customer\_managed\_keys with use\_cases=["MANAGED\_SERVICES"]) for encrypting workspace notebooks and secrets in the control plane. Leave null to use Databricks-managed encryption. | `string` | `null` | no |
| <a name="input_network_connectivity_config_id"></a> [network\_connectivity\_config\_id](#input\_network\_connectivity\_config\_id) | Optional. Network Connectivity Config (NCC) ID to bind to the workspace, enabling serverless private connectivity to data sources. Leave null if no NCC is required. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region in which to create the serverless workspace (e.g. "us-east-1", "us-gov-west-1"). | `string` | n/a | yes |
| <a name="input_workspace_name"></a> [workspace\_name](#input\_workspace\_name) | Display name for the workspace in the Databricks UI. Must be unique within the Databricks account. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_databricks_account_host"></a> [databricks\_account\_host](#output\_databricks\_account\_host) | Databricks account console host URL computed from databricks\_gov\_shard. Useful for configuring the account provider in the root composition. |
| <a name="output_ncc_binding_id"></a> [ncc\_binding\_id](#output\_ncc\_binding\_id) | ID of the NCC binding resource, or null if no network\_connectivity\_config\_id was provided. |
| <a name="output_workspace_host"></a> [workspace\_host](#output\_workspace\_host) | Workspace URL without trailing slash — identical to workspace\_url. Provided as a convenience alias for provider host arguments. |
| <a name="output_workspace_id"></a> [workspace\_id](#output\_workspace\_id) | Databricks workspace ID. Use as input to workspace-scoped modules and the workspace provider's workspace\_id. |
| <a name="output_workspace_status"></a> [workspace\_status](#output\_workspace\_status) | Current provisioning status of the workspace (e.g. RUNNING, PROVISIONING, FAILED). Useful for debugging and downstream conditional logic. |
| <a name="output_workspace_status_message"></a> [workspace\_status\_message](#output\_workspace\_status\_message) | Human-readable message accompanying workspace\_status. Populated on error to aid diagnosis. |
| <a name="output_workspace_url"></a> [workspace\_url](#output\_workspace\_url) | Full HTTPS URL of the workspace (e.g. https://my-ws.cloud.databricks.com). Use as the host for the workspace-scoped Databricks provider. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each `databricks_gov_shard` value (null, civilian, dod) produces the correct computed account host
- Invalid `databricks_gov_shard` is rejected by variable validation
- Invalid `workspace_name` (empty, too long, invalid chars) is rejected
- Invalid `region` is rejected
- `compute_mode = "SERVERLESS"` is set on the workspace resource
- NCC binding count is 0 without `network_connectivity_config_id`, 1 with it

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks account) verifies actual workspace creation. It is credential-gated and includes the tier-failure case per DATABRICKS_RULES.md Rule 4.1.
