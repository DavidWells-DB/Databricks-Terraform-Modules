# aws-account-network-vpc

Creates the VPC, subnets (private, optional public, optional PrivateLink-dedicated), route tables, and the Databricks-required security group in AWS, then registers the network configuration with the Databricks account API via `databricks_mws_networks`.

## What this module abstracts

"The network Databricks uses for this workspace" — one indivisible function. The AWS VPC and its Databricks-side registration are paired per DATABRICKS_RULES.md Rule 1.4: splitting them produces thin wrappers; pairing them produces a real abstraction.

## When to use

- You're provisioning a new AWS-hosted Databricks workspace and need the underlying VPC.
- You want a single module that creates the VPC resources AND registers them as a Databricks network configuration.
- You're deploying to AWS commercial or GovCloud (civilian or DoD) — parameterized via `databricks_gov_shard`.

## When NOT to use

- You already have a `databricks_mws_networks` registration you want to reuse — use a `data` source at the root composition instead.
- You're on Azure or GCP — they use different network mechanisms.
- You need internet egress (NAT gateway) — use `aws-account-network-egress-internet` and pass this module's `private_route_table_ids` and `public_subnet_ids` as inputs.
- You need AWS service VPC endpoints (S3, STS, Kinesis) — use `aws-account-network-vpc-endpoints`.
- You need Databricks PrivateLink endpoints — use `aws-account-network-privatelink-endpoints` and pass its outputs into this module's `vpc_endpoint_ids` input.

## Minimum platform tier

**Premium.** The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject the workspace creation that depends on this network. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## GovCloud parameterization

The `databricks_gov_shard` input parameterizes the module for AWS GovCloud deployments per DATABRICKS_RULES.md Rule 1.5. The provider-level configuration (account host URL) is handled in the root composition:

| Shard | `databricks_gov_shard` | Databricks account host |
|---|---|---|
| Commercial | `null` (default) | `https://accounts.cloud.databricks.com` |
| GovCloud civilian | `"civilian"` | `https://accounts.cloud.databricks.us` |
| GovCloud DoD | `"dod"` | `https://accounts-dod.cloud.databricks.mil` |

Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account host for the target shard. The AWS provider must be configured for the target region.

## PrivateLink wiring

Pass `vpc_endpoint_ids` from `aws-account-network-privatelink-endpoints` to enable PrivateLink connectivity. The module conditionally includes the `vpc_endpoints` block in `databricks_mws_networks` only when endpoint IDs are provided.

## Subnet design

- **Private subnets:** Used by Databricks compute (driver and worker nodes). At least two required for HA across AZs.
- **Public subnets:** Optional. Required only when deploying NAT gateways via `aws-account-network-egress-internet`.
- **PrivateLink subnets:** Optional. Dedicated subnets for PrivateLink interface endpoints, isolated from compute traffic.

## Security group

The security group enforces Databricks's documented minimum rules:
- Ingress: all traffic from within the same security group (cluster node-to-node communication).
- Egress: all traffic (required for control plane connectivity and package installation).

To restrict egress, use `aws-account-network-firewall` instead of this module's default egress rule.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.50 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | >= 1.50 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.privatelink](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [databricks_mws_networks.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_networks) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_azs"></a> [azs](#input\_azs) | List of availability zone names (e.g. ["us-east-1a", "us-east-1b"]). Must have the same length as private\_subnet\_cidrs. Also used for public and PrivateLink subnets when those lists are non-empty. | `list(string)` | n/a | yes |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Used to register the network configuration with the Databricks account API. | `string` | n/a | yes |
| <a name="input_databricks_gov_shard"></a> [databricks\_gov\_shard](#input\_databricks\_gov\_shard) | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. | `string` | `null` | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Name for the databricks\_mws\_networks registration. Should be descriptive and unique within the Databricks account. | `string` | n/a | yes |
| <a name="input_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#input\_private\_subnet\_cidrs) | List of CIDR blocks for private subnets. Must provide at least two subnets (one per AZ) for Databricks HA. Each CIDR must be a valid subnet of vpc\_cidr. | `list(string)` | n/a | yes |
| <a name="input_privatelink_subnet_cidrs"></a> [privatelink\_subnet\_cidrs](#input\_privatelink\_subnet\_cidrs) | Optional list of CIDR blocks for PrivateLink-dedicated subnets. Leave empty to skip PrivateLink subnet creation. Required when deploying aws-account-network-privatelink-endpoints. | `list(string)` | `[]` | no |
| <a name="input_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#input\_public\_subnet\_cidrs) | Optional list of CIDR blocks for public subnets. Leave empty to skip public subnet creation. Required if deploying NAT gateways or internet-facing resources. | `list(string)` | `[]` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix used to name all created resources (VPC, subnets, security group, route tables). Must be 1-32 characters, alphanumeric and hyphens only. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all AWS resources created by this module. | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC. Must be a valid IPv4 CIDR (e.g. "10.0.0.0/16"). Databricks requires a minimum /16 for the workspace VPC. | `string` | n/a | yes |
| <a name="input_vpc_endpoint_ids"></a> [vpc\_endpoint\_ids](#input\_vpc\_endpoint\_ids) | Optional PrivateLink VPC endpoint IDs from aws-account-network-privatelink-endpoints. When provided, wired into the databricks\_mws\_networks registration to enable PrivateLink connectivity. Set to null to skip PrivateLink wiring. | <pre>object({<br/>    rest_api_id = optional(string)<br/>    relay_id    = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_databricks_account_host"></a> [databricks\_account\_host](#output\_databricks\_account\_host) | Databricks account host URL derived from databricks\_gov\_shard. Useful for root composition validation that the databricks.account provider is configured against the correct host. |
| <a name="output_databricks_network_id"></a> [databricks\_network\_id](#output\_databricks\_network\_id) | Databricks network configuration ID from databricks\_mws\_networks. Pass to workspace creation modules as their network\_id input. |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | Map of private subnet name to route table ID. Pass to aws-account-network-egress-internet and aws-account-network-vpc-endpoints (S3 gateway) as their private\_route\_table\_ids input. |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | Map of private subnet name to subnet ID. Pass to aws-account-network-vpc-endpoints as its private\_subnet\_ids input. |
| <a name="output_privatelink_subnet_ids"></a> [privatelink\_subnet\_ids](#output\_privatelink\_subnet\_ids) | Map of PrivateLink subnet name to subnet ID. Pass to aws-account-network-privatelink-endpoints as its privatelink\_subnet\_ids input. Empty when no privatelink\_subnet\_cidrs are configured. |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | Map of public subnet name to subnet ID. Pass to aws-account-network-egress-internet as its public\_subnet\_ids input. Empty when no public\_subnet\_cidrs are configured. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the Databricks-required security group. Pass to aws-account-network-vpc-endpoints as its security\_group\_id input. |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | CIDR block of the VPC. Useful for constructing security group rules or firewall policies in downstream modules. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the created VPC. Pass to downstream modules (e.g., aws-account-network-egress-internet, aws-account-network-vpc-endpoints) as their vpc\_id input. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each `databricks_gov_shard` value (null, civilian, dod) is accepted.
- Invalid `databricks_gov_shard` is rejected by variable validation.
- Invalid `resource_prefix` (too long, invalid chars) is rejected by variable validation.
- Invalid `vpc_cidr` is rejected by variable validation.
- `private_subnet_cidrs` with fewer than 2 entries is rejected.
- `azs` with fewer than 2 entries is rejected.
- Invalid AZ name format is rejected.
- VPC resource is planned with expected CIDR.
- Security group resource is planned with expected name.
- `databricks_mws_networks` registration references correct VPC.
- `vpc_endpoints` block present when `vpc_endpoint_ids` provided; absent when null.

Run with `terraform test` from the module root.

An apply-command integration test (against a real AWS + Databricks account) verifies actual VPC creation and network registration. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
