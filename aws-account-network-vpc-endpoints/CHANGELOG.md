# Changelog

All notable changes to the `aws-account-network-vpc-endpoints` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: creates S3 gateway endpoint, STS interface endpoint, and Kinesis Streams interface endpoint for Databricks compute nodes in a private VPC.
- GovCloud parameterization via `databricks_gov_shard` input (null for commercial, "civilian", "dod") driving AWS partition in endpoint policy ARNs.
- Variable validation on `vpc_id` (vpc- prefix pattern), `region` (region name pattern), `private_subnet_ids` (subnet- prefix, non-empty), `security_group_ids` (sg- prefix, non-empty), `private_route_table_ids` (rtb- prefix, non-empty), `databricks_gov_shard` (enumerated values).
- Endpoint policies for all three endpoints using `aws_iam_policy_document`.
- Outputs: `s3_endpoint_id`, `s3_endpoint_arn`, `s3_cidr_blocks`, `sts_endpoint_id`, `sts_endpoint_arn`, `sts_dns_entries`, `kinesis_endpoint_id`, `kinesis_endpoint_arn`, `kinesis_dns_entries`, `aws_partition`.
- `examples/basic/` — minimum invocation against commercial AWS with an existing VPC.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering gov_shard branching, service name construction, resource attribute assertions, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).
