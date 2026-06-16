# dbx-workspace-network-serverless

Binds a Network Connectivity Config (NCC) to a Databricks workspace for serverless compute private connectivity, with optional cloud-specific private endpoint rules and workspace network policy assignment.

## What this module abstracts

"The serverless network security configuration for a workspace" — one indivisible function. Binding an NCC, creating its private endpoint rules, and assigning a network policy are three tightly-coupled operations that together establish private connectivity for serverless compute. Separating them would produce thin wrappers with no independent reuse value.

This module is cloud-agnostic at the Databricks API level. Private endpoint rule fields differ by cloud (AWS vs Azure), but the module accepts a unified `private_endpoint_rules` list and populates only the fields relevant to the target cloud.

## When to use

- You are enabling serverless compute private connectivity for an existing Databricks workspace.
- You want a single module that binds the NCC, creates private endpoint rules, and optionally assigns a network policy.
- You're on AWS or Azure (NCC binding is not supported on GCP at this time).

## When NOT to use

- You need to **create** the NCC itself — use a separate `databricks_mws_network_connectivity_config` resource or module, then pass its ID here.
- You need to **create** the workspace — use a cloud-specific workspace module, then pass the workspace ID here.
- You're on GCP — NCC binding is AWS/Azure only.

## Minimum platform tier

**Premium.** The NCC and serverless private connectivity features require a Premium (or Enterprise) workspace. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier workspace, the API will reject the operation and the apply will fail. See DATABRICKS_RULES.md Rules 2.3 and 4.1.

## Provider configuration

This module requires both `databricks.account` and `databricks.workspace` provider aliases per DATABRICKS_RULES.md Rule 2.2:

- `databricks.account` — used for `databricks_mws_ncc_binding` and `databricks_mws_ncc_private_endpoint_rule` (account-level resources).
- `databricks.workspace` — used for `databricks_workspace_network_option` (workspace-level resource; only provisioned when `network_policy_id` is supplied).

The caller MUST pass both provider aliases at the module call site:

```hcl
module "workspace_network_serverless" {
  source = "..."

  providers = {
    databricks.account   = databricks.account
    databricks.workspace = databricks.workspace
  }

  workspace_id                   = var.workspace_id
  network_connectivity_config_id = var.ncc_id
}
```

## Private endpoint rule fields by cloud

| Field | AWS | Azure |
|---|---|---|
| `endpoint_service` | Full VPC endpoint service name (e.g. `com.amazonaws.us-east-1.s3`) | Not used |
| `resource_names` | S3 bucket names; mutually exclusive with `domain_names` | Not used |
| `enabled` | Activation status for S3 endpoints (default `true`) | Not used |
| `resource_id` | Not used | Azure resource ID of target resource |
| `group_id` | Not used | Sub-resource type: `blob`, `dfs`, `sqlServer`; mutually exclusive with `domain_names` |
| `domain_names` | FQDNs via VPC endpoint | Domain names for private link service |

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.81.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | >= 1.81.0 |
| <a name="provider_databricks.workspace"></a> [databricks.workspace](#provider\_databricks.workspace) | >= 1.81.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_mws_ncc_binding.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_ncc_binding) | resource |
| [databricks_mws_ncc_private_endpoint_rule.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_ncc_private_endpoint_rule) | resource |
| [databricks_workspace_network_option.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/workspace_network_option) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_network_connectivity_config_id"></a> [network\_connectivity\_config\_id](#input\_network\_connectivity\_config\_id) | Canonical unique identifier of the Network Connectivity Config (NCC) in the Databricks account. The NCC and workspace must be in the same region. | `string` | n/a | yes |
| <a name="input_network_policy_id"></a> [network\_policy\_id](#input\_network\_policy\_id) | Network policy ID to assign to the workspace via databricks\_workspace\_network\_option. Controls network access for all serverless compute in the workspace. If null, the workspace\_network\_option resource is not created and the workspace retains its existing policy (or the Databricks default). Pass "default-policy" to explicitly assign the account default. | `string` | `null` | no |
| <a name="input_private_endpoint_rules"></a> [private\_endpoint\_rules](#input\_private\_endpoint\_rules) | List of private endpoint rules to create on the NCC. Each element maps to one databricks\_mws\_ncc\_private\_endpoint\_rule. The key field must be unique and is used as the Terraform map key. Omit fields that are not applicable to the target cloud. | <pre>list(object({<br/>    # Human-readable key used as the for_each map key; must be unique within the list.<br/>    key = string<br/><br/>    # --- Azure fields ---<br/>    # Azure resource ID of the target resource (e.g. storage account). Required for Azure PE rules.<br/>    resource_id = optional(string)<br/>    # Sub-resource type on Azure: "blob", "dfs", "sqlServer", etc.<br/>    # Mutually exclusive with domain_names on Azure.<br/>    group_id = optional(string)<br/><br/>    # --- AWS fields ---<br/>    # Full AWS VPC endpoint service name (e.g. "com.amazonaws.us-east-1.s3").<br/>    endpoint_service = optional(string)<br/>    # S3 bucket names accessible via the VPC endpoint. Mutually exclusive with domain_names on AWS.<br/>    resource_names = optional(list(string))<br/>    # Activation status for AWS S3 service endpoints. Defaults to true.<br/>    enabled = optional(bool, true)<br/><br/>    # --- Shared (Azure domain-based / AWS FQDN) ---<br/>    # On Azure: domain names for private link service.<br/>    # On AWS: FQDNs accessible via VPC endpoint.<br/>    # On Azure, mutually exclusive with group_id. On AWS, mutually exclusive with resource_names.<br/>    domain_names = optional(list(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_workspace_id"></a> [workspace\_id](#input\_workspace\_id) | Databricks workspace ID to bind to the NCC. A workspace can be bound to only one NCC at a time; binding a different NCC overwrites the previous binding. | `number` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ncc_binding_id"></a> [ncc\_binding\_id](#output\_ncc\_binding\_id) | Composite identifier of the NCC binding in the format <network\_connectivity\_config\_id>\|<workspace\_id>. Useful for referencing the binding in downstream resources. |
| <a name="output_network_connectivity_config_id"></a> [network\_connectivity\_config\_id](#output\_network\_connectivity\_config\_id) | Network Connectivity Config ID that is bound to the workspace. Echoed for convenience when building downstream configurations. |
| <a name="output_network_policy_id"></a> [network\_policy\_id](#output\_network\_policy\_id) | Network policy ID assigned to the workspace. Null when network\_policy\_id was not provided and databricks\_workspace\_network\_option was not created. |
| <a name="output_private_endpoint_rule_ids"></a> [private\_endpoint\_rule\_ids](#output\_private\_endpoint\_rule\_ids) | Map of private endpoint rule IDs keyed by the rule key input. Empty map when no rules are configured. |
| <a name="output_workspace_id"></a> [workspace\_id](#output\_workspace\_id) | Workspace ID that the NCC is bound to. Echoed for convenience when chaining module outputs. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- NCC binding resource is planned with correct `network_connectivity_config_id` and `workspace_id`
- Private endpoint rules are created for each entry with unique keys
- `databricks_workspace_network_option` is created only when `network_policy_id` is non-null
- Invalid `network_connectivity_config_id` (not a UUID) is rejected by variable validation
- Duplicate `key` values in `private_endpoint_rules` are rejected by variable validation

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks account + workspace) verifies actual NCC binding and PE rule creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
