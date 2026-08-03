# dbx-workspace-network-policy-binding

Binds an existing account serverless network policy to a Databricks workspace via `databricks_workspace_network_option`. This is the binding step **only** — it does not create the policy and does not require a Network Connectivity Config (NCC).

## What this module abstracts

"Assign a network policy to a workspace" — one indivisible function. A standalone `databricks_account_network_policy` has no effect until it is bound to a workspace; the policy alone is a dangling no-op. This module is that binding.

It exists because the only other binding path, [`dbx-workspace-network-serverless`](../dbx-workspace-network-serverless), couples the binding to an NCC (a Secure+ feature). A workspace that only needs a restricted-egress policy — the serverless **Default** rung — must not be forced to stand up an NCC just to bind a policy (open-item E5).

## When to use

- You have created an account network policy (see [`dbx-account-network-policy`](../dbx-account-network-policy)) and need to bind it to a workspace.
- You do **not** need an NCC / private endpoint rules (if you do, use [`dbx-workspace-network-serverless`](../dbx-workspace-network-serverless), which does both).

## When NOT to use

- You need NCC binding or private endpoint rules → use `dbx-workspace-network-serverless`.
- You need to create the policy itself → use `dbx-account-network-policy` (compose it with this module).

## Provider surface

`databricks_workspace_network_option` is an **account-surface** resource ("can only be used with an account-level provider" — provider docs). Binding it via a workspace provider fails at apply with "Not Found" (open-item E8). This module declares only `databricks.account`.

## Destroy ordering

When this binding is torn down together with its upstream policy, the policy delete can fire before the control plane finishes propagating the unbind, failing with `failed to delete account_network_policy` and succeeding only on retry (open-item E12). The module inserts a `time_sleep` (`unbind_settle_duration`, default `30s`) that runs on destroy **between** the binding delete and any dependent policy delete, so a single `terraform destroy` succeeds. There is no create-time delay.

## Minimum platform tier

Premium (serverless network policies require Premium+).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.81.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | 1.122.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.14.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_workspace_network_option.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/workspace_network_option) | resource |
| [time_sleep.unbind_settle](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_network_policy_id"></a> [network\_policy\_id](#input\_network\_policy\_id) | Account network policy ID to assign to the workspace via databricks\_workspace\_network\_option. This is the ID of a databricks\_account\_network\_policy (see the dbx-account-network-policy module). Pass "default-policy" to assign the account default policy. | `string` | n/a | yes |
| <a name="input_workspace_id"></a> [workspace\_id](#input\_workspace\_id) | Databricks workspace ID to bind the network policy to. A workspace has exactly one network option; binding a different policy overwrites the previous assignment. | `number` | n/a | yes |
| <a name="input_unbind_settle_duration"></a> [unbind\_settle\_duration](#input\_unbind\_settle\_duration) | How long to wait, on destroy, between unbinding the network policy from the workspace and allowing a dependent policy to be deleted. Fixes a delete-ordering race (open-item E12) where the policy delete fired before the unbind had propagated. Accepts Go duration syntax (e.g. "30s", "1m"). Applied on destroy only — no create delay. | `string` | `"30s"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_binding_id"></a> [binding\_id](#output\_binding\_id) | Composite binding identifier in the format <workspace\_id>\|<network\_policy\_id>. The databricks\_workspace\_network\_option resource exports no id, so this is synthesized for referencing the binding in downstream tooling or expressing explicit dependencies. |
| <a name="output_network_policy_id"></a> [network\_policy\_id](#output\_network\_policy\_id) | Network policy ID bound to the workspace. Echoed for convenience when chaining module outputs. |
| <a name="output_workspace_id"></a> [workspace\_id](#output\_workspace\_id) | Workspace ID the network policy is bound to. Echoed for convenience when chaining module outputs. |
<!-- END_TF_DOCS -->
