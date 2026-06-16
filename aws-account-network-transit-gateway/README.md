# aws-account-network-transit-gateway

Creates an AWS Transit Gateway with VPC attachments and a shared route table that moves traffic between attached VPCs and shared services. Route table associations and propagations are managed for every attached VPC so that all participants can route through the Transit Gateway immediately after apply.

## What this module abstracts

"The Transit Gateway hub for a Databricks deployment" — one indivisible function. A single Transit Gateway resource alone is not useful; it becomes useful only when paired with VPC attachments and the route tables that wire them together. This module encapsulates that complete hub-and-spoke foundation.

## When to use

- You are building a hub-and-spoke network topology for one or more Databricks workspaces on AWS.
- You need a Transit Gateway that connects Databricks workspace VPCs to shared-services VPCs (egress, inspection, on-premises via VPN/Direct Connect).
- You want all VPCs attached at creation time to share a single route table with mutual propagation.

## When NOT to use

- You need per-attachment route table isolation (asymmetric routing between segments). In that case, call this module once per routing segment and wire them at the root composition.
- You already have a Transit Gateway managed elsewhere — use a `data "aws_ec2_transit_gateway"` source at the root composition and pass the TGW ID directly to attachment resources.
- You are on Azure or GCP — they use different inter-VNet/VPC connectivity mechanisms.

## Minimum platform tier

**Premium.** This module is used to provision network infrastructure for Databricks workspaces that require Premium-tier features. The AWS Transit Gateway itself has no Databricks tier requirement, but the Databricks workspace consuming this network requires Premium tier. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## GovCloud notes

This module is fully compatible with AWS GovCloud (us-gov-west-1, us-gov-east-1). No changes to module inputs are required — configure the `aws` provider for the GovCloud region in the root composition. Transit Gateway resource types and API surface are identical across commercial and GovCloud partitions.

## Provider configuration

This module uses only the `aws` provider. Configure the `aws` provider in the root composition with the appropriate region and credentials. No Databricks provider is required because Transit Gateway is a pure AWS construct that Databricks does not register at the account level.

## Route table design

The module creates one shared route table and associates every VPC attachment to it. All attachments propagate their VPC CIDR into this route table, so every attached VPC can reach every other attached VPC through the Transit Gateway.

To add static routes (e.g., a default route to an inspection VPC or an on-premises CIDR via VPN), use `aws_ec2_transit_gateway_route` resources in the root composition, referencing `module.<name>.route_table_id`.

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
| [aws_ec2_transit_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |
| [aws_ec2_transit_gateway_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table) | resource |
| [aws_ec2_transit_gateway_route_table_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_vpc_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_default_route_table_association"></a> [default\_route\_table\_association](#input\_default\_route\_table\_association) | Whether attachments are automatically associated with the Transit Gateway's default route table. Must be "enable" or "disable". Disable when managing route table associations explicitly (recommended for Databricks hub-and-spoke topologies). | `string` | `"disable"` | no |
| <a name="input_default_route_table_propagation"></a> [default\_route\_table\_propagation](#input\_default\_route\_table\_propagation) | Whether attachments automatically propagate routes to the Transit Gateway's default route table. Must be "enable" or "disable". Disable when managing route propagations explicitly (recommended for Databricks hub-and-spoke topologies). | `string` | `"disable"` | no |
| <a name="input_dns_support"></a> [dns\_support](#input\_dns\_support) | Whether DNS resolution support is enabled on the Transit Gateway. Must be "enable" or "disable". | `string` | `"enable"` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix applied to all resource names created by this module (Transit Gateway, route tables). Use a short, consistent identifier such as your team or environment name. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources created by this module. | `map(string)` | `{}` | no |
| <a name="input_tgw_asn"></a> [tgw\_asn](#input\_tgw\_asn) | Private Autonomous System Number (ASN) for the Transit Gateway's BGP sessions. Must be in the private ASN range: 64512-65534 (16-bit) or 4200000000-4294967294 (32-bit). | `number` | n/a | yes |
| <a name="input_vpc_attachments"></a> [vpc\_attachments](#input\_vpc\_attachments) | Map of attachment name to VPC attachment configuration. Each entry creates one Transit Gateway VPC attachment. The key becomes the attachment's Name tag. subnet\_ids must each be in a different Availability Zone within the VPC. | <pre>map(object({<br/>    vpc_id     = string<br/>    subnet_ids = list(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_vpn_ecmp_support"></a> [vpn\_ecmp\_support](#input\_vpn\_ecmp\_support) | Whether Equal Cost Multi-path (ECMP) routing over VPN tunnels is enabled. Must be "enable" or "disable". | `string` | `"enable"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_attachment_ids"></a> [attachment\_ids](#output\_attachment\_ids) | Map of attachment name to Transit Gateway VPC attachment ID. Keys match the keys in var.vpc\_attachments. |
| <a name="output_route_table_id"></a> [route\_table\_id](#output\_route\_table\_id) | ID of the Transit Gateway route table shared by all VPC attachments. Use this when adding static routes from the root composition. |
| <a name="output_route_table_ids"></a> [route\_table\_ids](#output\_route\_table\_ids) | Map containing the single route table ID keyed by "shared". Provided for compatibility with callers that expect a map. For most callers, route\_table\_id is sufficient. |
| <a name="output_transit_gateway_arn"></a> [transit\_gateway\_arn](#output\_transit\_gateway\_arn) | ARN of the Transit Gateway. Useful for RAM (Resource Access Manager) sharing across AWS accounts. |
| <a name="output_transit_gateway_id"></a> [transit\_gateway\_id](#output\_transit\_gateway\_id) | ID of the Transit Gateway. Pass to VPC route resources or other network modules that need to forward traffic through this TGW. |
| <a name="output_transit_gateway_owner_id"></a> [transit\_gateway\_owner\_id](#output\_transit\_gateway\_owner\_id) | AWS account ID that owns the Transit Gateway. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid configuration produces expected resource attributes (TGW name, attachment names, route table name)
- Invalid `resource_prefix` (empty, too long, invalid characters) is rejected by variable validation
- Invalid `tgw_asn` (outside private ranges) is rejected by variable validation
- Invalid `dns_support` / `vpn_ecmp_support` / `default_route_table_*` values are rejected
- Empty `subnet_ids` in a vpc_attachment is rejected

Run with `terraform test` from the module root.

An apply-command integration test (against a real AWS account) verifies actual Transit Gateway creation and VPC attachment. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
