# Account NCC private endpoint rules

Owns private endpoint rules on an existing NCC without owning a workspace
binding. Use this in the same account foundation root that creates the NCC.
Workspace roots bind the NCC and network policy separately.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.81 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | >= 1.81 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [databricks_mws_ncc_private_endpoint_rule.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_ncc_private_endpoint_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud"></a> [cloud](#input\_cloud) | Cloud whose private endpoint fields are required: aws or azure. | `string` | n/a | yes |
| <a name="input_network_connectivity_config_id"></a> [network\_connectivity\_config\_id](#input\_network\_connectivity\_config\_id) | NCC that owns these private endpoint rules. | `string` | n/a | yes |
| <a name="input_private_endpoint_rules"></a> [private\_endpoint\_rules](#input\_private\_endpoint\_rules) | Private endpoint rules with stable caller-selected keys. Azure uses resource\_id + group\_id or domain\_names; AWS uses endpoint\_service + resource\_names or domain\_names. | <pre>list(object({<br/>    key              = string<br/>    resource_id      = optional(string)<br/>    group_id         = optional(string)<br/>    endpoint_service = optional(string)<br/>    resource_names   = optional(list(string))<br/>    enabled          = optional(bool, true)<br/>    domain_names     = optional(list(string))<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rule_ids"></a> [rule\_ids](#output\_rule\_ids) | Private endpoint rule IDs keyed by the caller's stable keys. |
<!-- END_TF_DOCS -->
