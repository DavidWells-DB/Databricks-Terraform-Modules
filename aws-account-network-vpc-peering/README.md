# aws-account-network-vpc-peering

Creates a VPC peering connection between two VPCs, accepts the connection, and installs bidirectional routes in both VPCs' route tables. Designed for direct VPC-to-VPC connectivity in Databricks AWS deployments — for example, peering the Databricks data-plane VPC with a hub or shared-services VPC to reach on-premises services, DNS, or other workloads.

## What this module abstracts

"A fully wired VPC peering connection" — one indivisible function. The AWS peering request, accepter, and bidirectional routes are three resources that are always created and destroyed together. Splitting them produces thin wrappers with no independent reuse; pairing them into one module produces a real connectivity abstraction.

## When to use

- You need direct, private VPC-to-VPC routing between a Databricks data-plane VPC and another VPC (hub, shared-services, on-premises egress VPC, etc.).
- The two VPCs are in the same AWS account (same-account peering) or in different accounts (cross-account peering).
- The two VPCs are in the same AWS region or in different regions (inter-region peering).
- You prefer a simpler peering model over Transit Gateway for workloads that do not require transitive routing or many-to-many VPC connectivity.

## When NOT to use

- You need transitive routing or hub-and-spoke connectivity across many VPCs — use a Transit Gateway module instead.
- Your VPCs have overlapping CIDR blocks — VPC peering requires non-overlapping CIDRs.
- You already have a peering connection and only need to manage routes — use the AWS provider `aws_route` resource directly at the root composition.
- You are on Azure or GCP — they use VNet peering or VPC peering mechanisms with different provider resources.

## Minimum platform tier

**Premium.** VPC peering for Databricks data-plane connectivity is a Premium-tier networking feature. Standard-tier accounts cannot use custom VPC networking; workspace creation will fail if the associated network uses a VPC that is peered but not otherwise provisioned correctly. See DATABRICKS_RULES.md Rule 2.3.

## GovCloud notes

This module supports both AWS commercial and GovCloud partitions. No GovCloud-specific branching is required at the module level — AWS VPC peering resource types and behavior are identical across partitions. Configure your AWS provider for the appropriate partition (`aws` or `aws-us-gov`) at the root composition. The `accepter_account_id` and `accepter_region` inputs handle cross-account and cross-region peering correctly in both partitions.

## Provider configuration notes

This module uses only the default `aws` provider. For cross-account peering, note that `aws_vpc_peering_connection_accepter` (which accepts the connection) must be able to act as the accepter account. This typically requires the AWS provider to be configured with credentials for the **accepter** account, or that the peering is within the same account.

For cross-account peering in practice:
- Pass credentials for the **requester** account to the default `aws` provider.
- The `accepter_account_id` input identifies the remote account; acceptance in that account may require a separate provider alias and separate root-composition wiring.
- If the accepter account is managed by a different team or Terraform workspace, use the `peering_connection_id` output and accept the connection separately.

This module's `aws_vpc_peering_connection_accepter` resource uses `auto_accept = true`, which works when the provider has access to accept on the accepter account (same-account or cross-account with appropriate credentials).

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
| [aws_route.accepter_to_requester](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.requester_to_accepter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_vpc_peering_connection.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection) | resource |
| [aws_vpc_peering_connection_accepter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_accepter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_accepter_account_id"></a> [accepter\_account\_id](#input\_accepter\_account\_id) | AWS account ID that owns the accepter VPC. Set to the same value as the requester's account ID for same-account peering, or a different account ID for cross-account peering. | `string` | n/a | yes |
| <a name="input_accepter_region"></a> [accepter\_region](#input\_accepter\_region) | AWS region of the accepter VPC. For same-region peering, set this to the same region as the requester. For cross-region peering, set to the accepter's region. | `string` | n/a | yes |
| <a name="input_accepter_route_table_ids"></a> [accepter\_route\_table\_ids](#input\_accepter\_route\_table\_ids) | Route table IDs in the accepter VPC that should receive a route back to the requester VPC's CIDR block. Typically includes all private route tables in the hub/shared-services VPC. | `list(string)` | n/a | yes |
| <a name="input_accepter_vpc_cidr"></a> [accepter\_vpc\_cidr](#input\_accepter\_vpc\_cidr) | CIDR block of the accepter VPC. Used to add a route in requester route tables pointing to the accepter VPC. | `string` | n/a | yes |
| <a name="input_accepter_vpc_id"></a> [accepter\_vpc\_id](#input\_accepter\_vpc\_id) | ID of the accepter (destination) VPC. This is typically the hub/shared-services VPC. | `string` | n/a | yes |
| <a name="input_peering_name"></a> [peering\_name](#input\_peering\_name) | Name tag applied to the VPC peering connection and its accepter. Should be descriptive and unique within the AWS account. | `string` | n/a | yes |
| <a name="input_requester_route_table_ids"></a> [requester\_route\_table\_ids](#input\_requester\_route\_table\_ids) | Route table IDs in the requester VPC that should receive a route to the accepter VPC's CIDR block. Typically includes all private route tables in the data-plane VPC. | `list(string)` | n/a | yes |
| <a name="input_requester_vpc_cidr"></a> [requester\_vpc\_cidr](#input\_requester\_vpc\_cidr) | CIDR block of the requester VPC. Used to add a route in accepter route tables pointing back to this VPC. | `string` | n/a | yes |
| <a name="input_requester_vpc_id"></a> [requester\_vpc\_id](#input\_requester\_vpc\_id) | ID of the requester (initiating) VPC. This is typically the Databricks data-plane VPC. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags applied to all taggable AWS resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_accepter_route_ids"></a> [accepter\_route\_ids](#output\_accepter\_route\_ids) | Map of accepter route table ID to the Terraform resource ID of the route added for the requester CIDR. Useful for debugging and dependency chaining. |
| <a name="output_peering_connection_id"></a> [peering\_connection\_id](#output\_peering\_connection\_id) | ID of the AWS VPC peering connection. Pass to downstream route or security-group rules that reference the peering link. |
| <a name="output_peering_connection_status"></a> [peering\_connection\_status](#output\_peering\_connection\_status) | Status of the VPC peering connection after acceptance (e.g., 'active'). Useful for verifying the connection is healthy. |
| <a name="output_requester_route_ids"></a> [requester\_route\_ids](#output\_requester\_route\_ids) | Map of requester route table ID to the Terraform resource ID of the route added for the accepter CIDR. Useful for debugging and dependency chaining. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid same-account same-region inputs produce expected peering and route resources.
- Invalid VPC ID format is rejected by variable validation.
- Invalid route table ID format is rejected by variable validation.
- Invalid CIDR block format is rejected by variable validation.
- Invalid accepter account ID format (non-12-digit) is rejected by variable validation.
- Invalid AWS region format is rejected by variable validation.
- Empty route table lists are rejected by variable validation.
- Peering connection uses the correct requester and accepter VPC IDs.
- Routes in both directions reference the accepted peering connection ID.

Run with `terraform test` from the module root.

An apply-command integration test (against a real AWS account) verifies actual VPC peering creation and route installation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
