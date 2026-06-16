# aws-account-network-vpc-endpoints

Creates the AWS VPC endpoints that Databricks compute nodes use to reach core AWS services (S3, STS, Kinesis) without traversing the internet or a NAT gateway: one S3 gateway endpoint and two interface endpoints (STS, Kinesis Streams).

## What this module abstracts

"The AWS service connectivity required for Databricks compute nodes in a private VPC" — three endpoint resources that are always provisioned together as part of Databricks network setup. The S3 gateway endpoint routes object storage traffic directly; the STS interface endpoint allows cross-account role assumption by the data plane; the Kinesis interface endpoint supports cluster log delivery. All three must exist for a well-configured Databricks workspace; creating them individually produces no useful intermediate state.

## When to use

- You are provisioning a new Databricks workspace on AWS and need private connectivity to S3, STS, and Kinesis from the workspace's VPC.
- You want Databricks compute nodes to reach AWS services without internet egress or a NAT gateway.
- You are deploying in commercial AWS or GovCloud (civilian or DoD).

## When NOT to use

- You already have S3, STS, and Kinesis VPC endpoints provisioned in the target VPC — use `data "aws_vpc_endpoint"` sources at the root composition to look them up.
- You need PrivateLink endpoints to the Databricks control plane itself — that is a separate concern covered by the `aws-account-network-privatelink-endpoints` module.
- You are on Azure or GCP — different connectivity models apply.

## Minimum platform tier

**Premium.** These endpoints are part of the Databricks network isolation model, which requires Premium tier. See DATABRICKS_RULES.md Rule 2.3.

## GovCloud parameterization

The `databricks_gov_shard` input drives the AWS partition used in endpoint policy ARN construction:

| Shard | `databricks_gov_shard` | AWS Partition |
|---|---|---|
| Commercial | `null` (default) | `aws` |
| GovCloud civilian | `"civilian"` | `aws-us-gov` |
| GovCloud DoD | `"dod"` | `aws-us-gov` |

Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud

## Provider configuration

This module uses only the `aws` provider. No Databricks provider is required — these are pure AWS resources. The AWS provider must be configured for the same region as the `region` input and the VPC.

## Endpoint types

| Endpoint | Type | Why |
|---|---|---|
| S3 | Gateway | High-throughput object storage; gateway endpoints are free and route via the route table |
| STS | Interface | Low-volume API calls; interface endpoints provide private DNS resolution |
| Kinesis Streams | Interface | Cluster log delivery; interface endpoints provide private DNS resolution |

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
| [aws_vpc_endpoint.kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_iam_policy_document.kinesis_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sts_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_databricks_gov_shard"></a> [databricks\_gov\_shard](#input\_databricks\_gov\_shard) | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. Drives the AWS partition used in endpoint policy ARNs. | `string` | `null` | no |
| <a name="input_private_route_table_ids"></a> [private\_route\_table\_ids](#input\_private\_route\_table\_ids) | Route table IDs to associate with the S3 gateway endpoint. Typically one per private subnet / availability zone. | `list(string)` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs for the STS and Kinesis interface endpoints. Databricks compute nodes reside in these subnets. | `list(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for endpoint service names (e.g., "us-east-1"). Must match the region of the VPC and subnets. | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Security group IDs to associate with the STS and Kinesis interface endpoints. Must allow HTTPS (443) from Databricks compute nodes. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all VPC endpoints created by this module. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC in which to create the VPC endpoints. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_aws_partition"></a> [aws\_partition](#output\_aws\_partition) | AWS partition computed from databricks\_gov\_shard. "aws" for commercial; "aws-us-gov" for GovCloud. Useful for verification and downstream ARN construction. |
| <a name="output_kinesis_dns_entries"></a> [kinesis\_dns\_entries](#output\_kinesis\_dns\_entries) | DNS entries for the Kinesis Streams interface endpoint. Each entry has dns\_name and hosted\_zone\_id attributes. |
| <a name="output_kinesis_endpoint_arn"></a> [kinesis\_endpoint\_arn](#output\_kinesis\_endpoint\_arn) | ARN of the Kinesis Streams interface VPC endpoint. |
| <a name="output_kinesis_endpoint_id"></a> [kinesis\_endpoint\_id](#output\_kinesis\_endpoint\_id) | ID of the Kinesis Streams interface VPC endpoint. |
| <a name="output_s3_cidr_blocks"></a> [s3\_cidr\_blocks](#output\_s3\_cidr\_blocks) | CIDR blocks managed by the S3 gateway endpoint for use in security group rules or route tables. |
| <a name="output_s3_endpoint_arn"></a> [s3\_endpoint\_arn](#output\_s3\_endpoint\_arn) | ARN of the S3 gateway VPC endpoint. |
| <a name="output_s3_endpoint_id"></a> [s3\_endpoint\_id](#output\_s3\_endpoint\_id) | ID of the S3 gateway VPC endpoint. Useful for referencing the endpoint in downstream route table or bucket policy configurations. |
| <a name="output_sts_dns_entries"></a> [sts\_dns\_entries](#output\_sts\_dns\_entries) | DNS entries for the STS interface endpoint. Each entry has dns\_name and hosted\_zone\_id attributes. |
| <a name="output_sts_endpoint_arn"></a> [sts\_endpoint\_arn](#output\_sts\_endpoint\_arn) | ARN of the STS interface VPC endpoint. |
| <a name="output_sts_endpoint_id"></a> [sts\_endpoint\_id](#output\_sts\_endpoint\_id) | ID of the STS interface VPC endpoint. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Commercial and GovCloud shard variants produce the correct AWS partition local
- Invalid `vpc_id`, `region`, `private_subnet_ids`, `security_group_ids`, `private_route_table_ids`, and `databricks_gov_shard` values are rejected by variable validation
- Endpoint service names are constructed correctly for the given region
- Resource attributes (endpoint type, subnet associations, private DNS) are planned with expected values

Run with `terraform test` from the module root.

An apply-command integration test (against a real AWS account with an existing VPC) verifies actual endpoint creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
