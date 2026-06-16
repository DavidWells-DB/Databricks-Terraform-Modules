# dbx-account-network-policy

Creates a Databricks account-level network policy that controls egress behavior for serverless compute resources.

## What this module abstracts

"Network policy for serverless compute egress" — a single account-level governance control. Network policies restrict or permit outbound traffic from serverless products (SQL warehouses, serverless notebooks, model serving endpoints) to internet destinations and storage targets.

## When to use

- You need to restrict serverless compute egress to specific destinations (allow-list mode).
- You need to permit unrestricted egress for serverless compute.
- You want centralized, account-level governance of serverless network behavior.

## When NOT to use

- You're configuring workspace-level network policies for classic compute (use workspace IP access lists instead).
- You need ingress controls — this module only configures egress policies.
- Your account is not Premium tier or higher.

## Minimum platform tier

**Premium.** Network policies are a Premium-tier feature. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Egress modes

| Mode | Description |
|---|---|
| `ALLOW_LIST` | Restrict egress to explicitly allowed destinations (default). Use `allowed_internet_destinations` and `allowed_storage_destinations` to define permitted targets. |
| `UNRESTRICTED` | Allow all internet egress. Storage destinations are still controlled by Unity Catalog external location policies. |

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account host (`https://accounts.cloud.databricks.com` for commercial, `https://accounts.cloud.databricks.us` for GovCloud civilian, `https://accounts-dod.cloud.databricks.mil` for GovCloud DoD).

## Example usage

See [examples/basic](./examples/basic) for a complete working example.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.60 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | >= 1.60 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_account_network_policy.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/account_network_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | Name for the network policy. Must be unique within the Databricks account. | `string` | n/a | yes |
| <a name="input_egress_mode"></a> [egress\_mode](#input\_egress\_mode) | Egress restriction mode for serverless compute. Use "ALLOW\_LIST" to restrict egress to allowed destinations; "UNRESTRICTED" to allow all internet egress. | `string` | `"ALLOW_LIST"` | no |
| <a name="input_allowed_internet_destinations"></a> [allowed\_internet\_destinations](#input\_allowed\_internet\_destinations) | Internet destinations (CIDR blocks or FQDNs) allowed when egress\_mode is ALLOW\_LIST. Each object must have 'destination' (CIDR or FQDN) and optionally 'internet\_destination\_type' (CIDR or FQDN). | <pre>list(object({<br>    destination               = string<br>    internet_destination_type = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_allowed_storage_destinations"></a> [allowed\_storage\_destinations](#input\_allowed\_storage\_destinations) | Storage targets accessible from serverless compute. For AWS, specify 'bucket\_name' and optionally 'region'; for Azure, specify 'azure\_storage\_account' and optionally 'azure\_storage\_service'. Optionally include 'storage\_destination\_type'. | <pre>list(object({<br>    bucket_name              = optional(string)<br>    azure_storage_account    = optional(string)<br>    azure_storage_service    = optional(string)<br>    region                   = optional(string)<br>    storage_destination_type = optional(string)<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_policy_id"></a> [network\_policy\_id](#output\_network\_policy\_id) | Databricks account-level network policy ID. Pass to workspace or serverless compute configuration as the network\_policy\_id input. |
| <a name="output_policy_name"></a> [policy\_name](#output\_policy\_name) | Name of the network policy. |
| <a name="output_egress_mode"></a> [egress\_mode](#output\_egress\_mode) | Egress restriction mode configured for the policy (ALLOW\_LIST or UNRESTRICTED). |
<!-- END_TF_DOCS -->
