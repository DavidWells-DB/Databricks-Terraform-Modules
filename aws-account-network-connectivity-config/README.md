# aws-account-network-connectivity-config

Creates a Databricks Network Connectivity Configuration (NCC) at the account level. An NCC is the serverless compute private-connectivity object that controls which egress destinations serverless workloads in attached workspaces may reach.

## What this module abstracts

"The serverless private-connectivity policy for a region" — one account-level Databricks object (`databricks_mws_network_connectivity_config`) that is registered once per region and then bound to one or more workspaces via `databricks_mws_ncc_binding`. This module handles only the NCC creation; workspace binding is performed by a separate binding module.

## When to use

- You need serverless compute (SQL warehouses, Model Serving, Workflows) in an AWS-hosted workspace to use stable egress IPs or private connectivity.
- You are establishing a new NCC for a region before attaching workspaces to it.
- You want a named, versioned Terraform resource for the NCC, as opposed to creating it via the Databricks UI or CLI.

## When NOT to use

- You already have an NCC you want to reuse — use a `data "databricks_mws_network_connectivity_config"` source (when available) at the root composition instead.
- You are on Azure or GCP — NCC has cloud-specific implementations; this module targets AWS.
- You need to bind an NCC to a workspace — use a dedicated `databricks_mws_ncc_binding` resource in the root composition or a binding module.
- You need private endpoint rules (per-destination NCC rules) — use `databricks_mws_ncc_private_endpoint_rule` at the root composition.

## Minimum platform tier

**Premium.** NCCs and serverless compute require at least a Premium-tier Databricks account. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject the request and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## GovCloud parameterization

NCCs are supported in AWS commercial and GovCloud regions. Pass the appropriate GovCloud region name (`us-gov-east-1`, `us-gov-west-1`) as the `region` input and configure the `databricks.account` provider with the matching GovCloud account host. No additional module-level input is required; GovCloud is parameterized at the provider level.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account host:

| Environment | Account host |
|---|---|
| Commercial | `https://accounts.cloud.databricks.com` |
| GovCloud civilian | `https://accounts.cloud.databricks.us` |
| GovCloud DoD | `https://accounts-dod.cloud.databricks.mil` |

No AWS provider is required — this module creates only a Databricks account-level resource.

## NCC limits

Databricks enforces a maximum of **10 NCCs per region per account**. Plan NCC allocation carefully before creating new ones.

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
| [databricks_mws_network_connectivity_config.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_network_connectivity_config) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name"></a> [name](#input\_name) | Name for the Network Connectivity Configuration. Must be 3-30 characters: alphanumeric, hyphens, or underscores. Forces replacement on change. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the Network Connectivity Configuration. NCCs can only be referenced by workspaces in the same region. Forces replacement on change. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_creation_time"></a> [creation\_time](#output\_creation\_time) | Epoch milliseconds timestamp when the NCC was created. Useful for auditing and ordering. |
| <a name="output_name"></a> [name](#output\_name) | Name of the Network Connectivity Configuration as registered in Databricks. |
| <a name="output_network_connectivity_config_id"></a> [network\_connectivity\_config\_id](#output\_network\_connectivity\_config\_id) | Databricks Network Connectivity Configuration ID. Pass to workspace binding modules (databricks\_mws\_ncc\_binding) as the network\_connectivity\_config\_id input. |
| <a name="output_region"></a> [region](#output\_region) | AWS region of the Network Connectivity Configuration. Only workspaces in this region can reference this NCC. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid region formats (commercial, GovCloud) are accepted; invalid formats are rejected
- NCC `name` constraints (3-30 chars, alphanumeric/hyphen/underscore) are enforced
- Resource is planned with expected `name` and `region` attribute values

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks account) verifies actual NCC creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
