# azure-account-network-connectivity-config

Creates a Databricks Network Connectivity Config (NCC) at the account level for Azure serverless private connectivity, with an optional account network policy for egress internet restrictions.

## What this module abstracts

"The network connectivity configuration Databricks uses for serverless private connectivity in this Azure region" — one indivisible function. The NCC and its optional network policy are paired: creating the NCC without the policy is the default (unrestricted) state; adding the policy activates RESTRICTED_ACCESS mode.

## When to use

- You're enabling serverless compute (serverless SQL warehouses, serverless jobs) in an Azure-hosted Databricks workspace and need stable IP egress through a private-connectivity NCC.
- You want to lock down egress to a specific allow-list of internet destinations via an account network policy.
- You're provisioning a new Azure region in your Databricks account (max 10 NCCs per region per account).

## When NOT to use

- You already have a `databricks_mws_network_connectivity_config` object you want to reuse — use a `data` source at the root composition instead.
- You're on AWS or GCP — they use different networking primitives.
- You need VNet injection or private endpoints for the workspace itself — use the `azure-account-network-vnet` and `azure-account-network-private-endpoints` modules for that.

## Minimum platform tier

**Premium.** The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Azure Government

Azure Government is parameterized via the `azurerm` provider `environment = "usgovernment"` setting — a provider-level concern handled in root compositions. This module has no cloud-side resources and therefore no `azurerm` dependency; the Databricks account-level API endpoint for Azure Government is handled by the `databricks.account` provider configuration passed in by the caller.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks Azure account host (`https://accounts.azuredatabricks.net`).

## Optional account network policy

When `allowed_internet_destinations` is set, the module creates a `databricks_account_network_policy` that places the account in `RESTRICTED_ACCESS` mode, limiting serverless egress to the specified DNS destinations. When `allowed_internet_destinations` is `null` (default), no policy resource is created and serverless compute has unrestricted internet access from the NCC.

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
| [databricks_account_network_policy.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/account_network_policy) | resource |
| [databricks_mws_network_connectivity_config.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_network_connectivity_config) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_internet_destinations"></a> [allowed\_internet\_destinations](#input\_allowed\_internet\_destinations) | List of internet destinations to allow when the account network policy is in RESTRICTED\_ACCESS mode. Each entry requires a destination (DNS name) and internet\_destination\_type (currently only "DNS\_NAME" is supported). When null, no account network policy is created and no internet restrictions are applied. | <pre>list(object({<br/>    destination               = string<br/>    internet_destination_type = string<br/>  }))</pre> | `null` | no |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Required by the account-level provider. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name for the Network Connectivity Config. Must be 3-30 characters and contain only alphanumeric characters, hyphens, or underscores. | `string` | n/a | yes |
| <a name="input_network_policy_id"></a> [network\_policy\_id](#input\_network\_policy\_id) | ID for the account network policy. Required when allowed\_internet\_destinations is set. Must be unique within the Databricks account. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Azure region where the NCC will be created. Must match the region of the workspaces that will use it (e.g., "eastus", "westeurope"). NCCs can only be associated with workspaces in the same region. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ncc_name"></a> [ncc\_name](#output\_ncc\_name) | Name of the Network Connectivity Config as registered in Databricks. |
| <a name="output_network_connectivity_config_id"></a> [network\_connectivity\_config\_id](#output\_network\_connectivity\_config\_id) | Databricks Network Connectivity Config ID. Pass to databricks\_mws\_ncc\_binding to attach this NCC to a workspace, or to databricks\_mws\_workspaces for direct association. |
| <a name="output_network_policy_id"></a> [network\_policy\_id](#output\_network\_policy\_id) | ID of the account network policy, or null when no policy was created (allowed\_internet\_destinations was not set). |
| <a name="output_region"></a> [region](#output\_region) | Azure region of the Network Connectivity Config. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- NCC resource is planned with expected name and region attributes.
- When `allowed_internet_destinations` is null, no network policy resource is planned.
- When `allowed_internet_destinations` is set, a network policy resource is planned with RESTRICTED_ACCESS mode.
- Invalid `name` values (too short, too long, invalid characters) are rejected by variable validation.
- Invalid `internet_destination_type` values are rejected by variable validation.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Azure + Databricks account) verifies actual NCC creation and optional policy registration. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
