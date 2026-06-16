# aws-account-network-firewall

Creates an AWS Network Firewall with an associated firewall policy and adds 0.0.0.0/0 routes on the provided private route tables to send egress traffic through the firewall endpoints instead of directly through a NAT gateway.

## What this module abstracts

"The Network Firewall that controls egress from Databricks compute subnets" — firewall resource, firewall policy, and per-AZ route updates are one indivisible deployment unit. Splitting them produces thin wrappers that a caller must wire together every time; this module encapsulates the full firewall+routing pairing.

## When to use

- You want stateful or stateless Layer 4/7 egress inspection for Databricks cluster traffic.
- You are replacing the default NAT-gateway-only egress path (`aws-account-network-egress-internet`) with a firewall-mediated path.
- You need domain-based (FQDN) or SNI-based egress filtering for Databricks control-plane traffic.

## When NOT to use

- You already have a 0.0.0.0/0 route on the same private route tables (e.g., from `aws-account-network-egress-internet`). The two modules are mutually exclusive for the same route tables — each writes a 0.0.0.0/0 default route and Terraform will conflict.
- You want NAT-only egress without deep packet inspection — use `aws-account-network-egress-internet` instead.
- You need to share a single firewall across multiple VPCs — use AWS Transit Gateway with a shared inspection VPC instead.

## Minimum platform tier

**Premium.** Databricks Network Firewall integration (restricting egress from workspace compute) is a Premium feature. The AWS Network Firewall itself does not require a Databricks tier, but the workspace whose egress it controls must be Premium or above to support the necessary security controls.

## GovCloud notes

AWS Network Firewall is available in GovCloud (us-gov-west-1, us-gov-east-1). No module-level parameterization is required — configure the AWS provider for the target region. GovCloud workspaces have the Compliance Security Profile auto-enabled; deploying this module alongside `aws-account-network-firewall` is strongly recommended for IL5/DoD compliance.

## Provider configuration

This module uses only the `aws` provider. No Databricks provider is required — the firewall is a pure AWS infrastructure resource. Configure the `aws` provider in your root composition for the target region.

## Route wiring behavior

The module adds a `0.0.0.0/0 → firewall-endpoint` route to each route table in `private_route_table_ids`. Route tables are paired to firewall endpoints by index (wrapping with modulo when there are more route tables than firewall AZs). The firewall endpoint IDs are only available after the firewall reaches READY state, so the routes are created in a second apply pass automatically by Terraform's dependency graph.

## Rule groups

This module creates no inline rule groups. Pass ARNs of externally-managed rule groups via `stateful_rule_group_arns` and `stateless_rule_group_arns`. This keeps rule group lifecycle independent of firewall deployment.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_networkfirewall_firewall.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall) | resource |
| [aws_networkfirewall_firewall_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy) | resource |
| [aws_route.private_firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_firewall_name"></a> [firewall\_name](#input\_firewall\_name) | Name for the AWS Network Firewall and its associated policy. Must be 1-128 characters, alphanumeric and hyphens only. | `string` | n/a | yes |
| <a name="input_firewall_subnet_ids"></a> [firewall\_subnet\_ids](#input\_firewall\_subnet\_ids) | List of subnet IDs in which the Network Firewall endpoints are deployed. One firewall endpoint is created per subnet. Subnets must be in distinct AZs for HA. At least one subnet is required. | `list(string)` | n/a | yes |
| <a name="input_private_route_table_ids"></a> [private\_route\_table\_ids](#input\_private\_route\_table\_ids) | List of private route table IDs to which the 0.0.0.0/0 route pointing to the firewall endpoint is added. Each route table receives a route to the firewall endpoint in the same AZ (by index). At least one route table ID is required. | `list(string)` | n/a | yes |
| <a name="input_stateful_rule_group_arns"></a> [stateful\_rule\_group\_arns](#input\_stateful\_rule\_group\_arns) | List of ARNs of stateful rule groups to associate with the firewall policy. May be empty if all filtering is handled by stateless rule groups. | `list(string)` | `[]` | no |
| <a name="input_stateless_default_actions"></a> [stateless\_default\_actions](#input\_stateless\_default\_actions) | Default actions for stateless packets not matching any stateless rule. Valid values: "aws:pass", "aws:drop", "aws:forward\_to\_sfe". At least one action is required. | `list(string)` | <pre>[<br/>  "aws:forward_to_sfe"<br/>]</pre> | no |
| <a name="input_stateless_fragment_default_actions"></a> [stateless\_fragment\_default\_actions](#input\_stateless\_fragment\_default\_actions) | Default actions for fragmented stateless packets not matching any stateless rule. Valid values: "aws:pass", "aws:drop", "aws:forward\_to\_sfe". At least one action is required. | `list(string)` | <pre>[<br/>  "aws:forward_to_sfe"<br/>]</pre> | no |
| <a name="input_stateless_rule_group_arns"></a> [stateless\_rule\_group\_arns](#input\_stateless\_rule\_group\_arns) | List of ARNs of stateless rule groups to associate with the firewall policy. May be empty. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all AWS resources created by this module (firewall, firewall policy, and routes). | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC in which the Network Firewall is deployed. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_firewall_arn"></a> [firewall\_arn](#output\_firewall\_arn) | ARN of the AWS Network Firewall. Use for IAM policies and CloudWatch log delivery configuration. |
| <a name="output_firewall_endpoint_ids"></a> [firewall\_endpoint\_ids](#output\_firewall\_endpoint\_ids) | List of VPC endpoint IDs for the Network Firewall endpoints, one per firewall subnet. Route tables point to these endpoints. |
| <a name="output_firewall_id"></a> [firewall\_id](#output\_firewall\_id) | ID of the AWS Network Firewall resource. |
| <a name="output_firewall_policy_arn"></a> [firewall\_policy\_arn](#output\_firewall\_policy\_arn) | ARN of the Network Firewall policy associated with the firewall. Useful for attaching additional rule groups post-creation. |
| <a name="output_firewall_policy_id"></a> [firewall\_policy\_id](#output\_firewall\_policy\_id) | ID of the Network Firewall policy. |
| <a name="output_firewall_status"></a> [firewall\_status](#output\_firewall\_status) | Full firewall\_status block from the aws\_networkfirewall\_firewall resource. Contains sync\_states per AZ with endpoint attachment details. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each variable validation (vpc_id format, firewall_name length/charset, subnet ID format, route table ID format, stateless action allowed values, rule group ARN format)
- Firewall and policy resource attribute checks
- Stateless/stateful rule group dynamic block presence/absence

Run with `terraform test` from the module root.

An apply-command integration test (against a real AWS account) verifies actual firewall creation and route table updates. It is credential-gated and is added when the test environment is wired.
