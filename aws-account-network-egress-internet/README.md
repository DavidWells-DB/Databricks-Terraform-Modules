# aws-account-network-egress-internet

Creates internet egress for private subnets in an existing VPC: one Internet Gateway, one or more Elastic IPs, one or more NAT Gateways (placed in caller-supplied public subnets), and a `0.0.0.0/0` route on each caller-supplied private route table pointing to the NAT Gateway.

## What this module abstracts

"Internet egress for private subnets" — the three resources that form one indivisible function: Internet Gateway (attached to the VPC), NAT Gateway (placed in a public subnet with an EIP), and the default route that sends private-subnet traffic through the NAT. Treating them as a unit raises the level of abstraction above individual route and gateway resources.

## When to use

- You're adding internet egress to an existing VPC that already has public subnets and private route tables (e.g., created by `aws-account-network-vpc`).
- You want private Databricks compute subnets to reach the internet through a managed NAT Gateway.
- You need one or more NAT Gateways for AZ-redundant HA (set `nat_gateway_count` accordingly).

## When NOT to use

- You want egress via AWS Network Firewall instead — use `aws-account-network-firewall`. Both modules write `0.0.0.0/0` to the same route tables; they are **mutually exclusive** for the same set of `private_route_table_ids`.
- Your VPC already has an Internet Gateway — adding a second IGW to the same VPC is not permitted by AWS.
- You need internet egress on Azure or GCP — those clouds use different constructs.

## Minimum platform tier

**Premium.** This module provisions AWS networking that supports Premium-tier Databricks workspace deployments. The AWS provider does not check Databricks tier at plan time. See DATABRICKS_RULES.md Rule 2.3.

## GovCloud notes

This module uses only the AWS provider and contains no Databricks-side resources. No `databricks_gov_shard` input is needed. AWS GovCloud regions (`us-gov-east-1`, `us-gov-west-1`) are supported transparently — configure the AWS provider with the target region at the root composition.

## Provider configuration

This module uses only the `aws` provider. No `configuration_aliases` are needed. Configure the AWS provider at the root composition for the target region.

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
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_nat_gateway_count"></a> [nat\_gateway\_count](#input\_nat\_gateway\_count) | Number of NAT Gateways to create. Default 1 is sufficient for non-HA deployments. Set to match the number of public subnets for full AZ-redundant HA. | `number` | `1` | no |
| <a name="input_private_route_table_ids"></a> [private\_route\_table\_ids](#input\_private\_route\_table\_ids) | List of private route table IDs to which the 0.0.0.0/0 → NAT Gateway route is added. At least one route table ID is required. | `list(string)` | n/a | yes |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | List of public subnet IDs into which the NAT Gateways are placed. At least one subnet is required. Each NAT Gateway is placed in the corresponding subnet by index (wrapping with modulo if fewer subnets than NAT Gateways). | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all AWS resources created by this module (Internet Gateway, Elastic IPs, NAT Gateways, and routes). | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC in which to create the Internet Gateway and NAT Gateway. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | ID of the Internet Gateway attached to the VPC. |
| <a name="output_nat_gateway_id"></a> [nat\_gateway\_id](#output\_nat\_gateway\_id) | ID of the first (or sole) NAT Gateway. Convenience alias for nat\_gateway\_ids[0] when nat\_gateway\_count = 1. |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | List of NAT Gateway IDs, in creation order. Pass individual entries to route-specific callers. |
| <a name="output_nat_public_ip"></a> [nat\_public\_ip](#output\_nat\_public\_ip) | Public Elastic IP of the first (or sole) NAT Gateway. Convenience alias for nat\_public\_ips[0] when nat\_gateway\_count = 1. |
| <a name="output_nat_public_ips"></a> [nat\_public\_ips](#output\_nat\_public\_ips) | List of public Elastic IP addresses (one per NAT Gateway), in the same order as nat\_gateway\_ids. Use for firewall allowlisting at egress. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid inputs produce expected resource attribute values (VPC ID, subnet assignment, route table association)
- Invalid `vpc_id` format rejected by variable validation
- Invalid `public_subnet_ids` format rejected by variable validation
- Invalid `private_route_table_ids` format rejected by variable validation
- Empty `public_subnet_ids` rejected by variable validation
- Empty `private_route_table_ids` rejected by variable validation
- `nat_gateway_count = 0` rejected by variable validation

Run with `terraform test` from the module root.

An apply-command integration test (against a real AWS account) verifies actual IGW, EIP, NAT Gateway creation and route installation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
