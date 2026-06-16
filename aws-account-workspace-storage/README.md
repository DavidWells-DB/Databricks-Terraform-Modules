# aws-account-workspace-storage

Creates an S3 bucket for workspace root storage (DBFS) — with versioning, server-side encryption, public access blocking, and the Databricks-required bucket policy — and registers it as a Databricks storage configuration via `databricks_mws_storage_configurations`.

## What this module abstracts

"The storage Databricks uses for this workspace's DBFS" — one indivisible function. The S3 bucket and its Databricks-side registration are paired per DATABRICKS_RULES.md Rule 1.4: splitting them produces thin wrappers; pairing them produces a real abstraction.

## When to use

- You're provisioning a new AWS-hosted Databricks workspace (commercial, GovCloud civilian, or GovCloud DoD).
- You want a single module that creates the S3 bucket AND registers it as a Databricks storage configuration.

## When NOT to use

- You already have a `databricks_mws_storage_configurations` object you want to reuse — use a `data` source at the root composition instead.
- You're on Azure or GCP — they use different storage mechanisms.
- Your S3 bucket is managed by a separate team — at the root composition, reference the existing bucket name and pass it directly to a `databricks_mws_storage_configurations` resource.

## Minimum platform tier

**Premium.** The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## GovCloud parameterization

The `databricks_gov_shard` input drives the Databricks control plane AWS account ID used in the bucket policy:

| Shard | `databricks_gov_shard` | `aws_partition` | Databricks AWS account ID |
|---|---|---|---|
| Commercial | `null` (default) | `"aws"` | `414351767826` |
| GovCloud civilian | `"civilian"` | `"aws-us-gov"` | `044793339203` |
| GovCloud DoD | `"dod"` | `"aws-us-gov"` | `170661010020` |

Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud

**GovCloud KMS requirement:** GovCloud workspaces require KMS encryption on the root bucket. Set `kms_key_arn` to the ARN of a customer-managed KMS key when deploying to GovCloud.

## Encryption

- When `kms_key_arn` is provided: SSE-KMS with bucket key enabled (cost-optimized).
- When `kms_key_arn` is null (default): SSE-S3 (AES-256), Databricks-managed keys.

## Bucket policy and ignore_changes

The Databricks bucket policy (`databricks_aws_bucket_policy` data source) is applied at creation time. Databricks modifies the bucket policy post-creation when it registers the workspace. This module includes `lifecycle { ignore_changes = [policy] }` on the `aws_s3_bucket_policy` resource per DATABRICKS_RULES.md Rule 3.2. External mutation is expected and documented.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account host:
- Commercial: `https://accounts.cloud.databricks.com`
- GovCloud civilian: `https://accounts.cloud.databricks.us`
- GovCloud DoD: `https://accounts-dod.cloud.databricks.mil`

The AWS provider must be configured for the same partition as the `aws_partition` input.

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
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [databricks_mws_storage_configurations.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_storage_configurations) | resource |
| [databricks_aws_bucket_policy.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/data-sources/aws_bucket_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition for ARN and bucket policy construction. Use "aws" for commercial; "aws-us-gov" for GovCloud (both civilian and DoD shards). | `string` | n/a | yes |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket to create. Must be globally unique. Follows S3 naming rules: 3-63 lowercase characters, numbers, or hyphens; must start and end with a letter or number. | `string` | n/a | yes |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Used when registering the S3 bucket as a storage configuration. | `string` | n/a | yes |
| <a name="input_databricks_gov_shard"></a> [databricks\_gov\_shard](#input\_databricks\_gov\_shard) | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. GovCloud workspaces require KMS encryption on the root bucket. | `string` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of the KMS key used for server-side encryption (SSE-KMS). Required for GovCloud workspaces. Omit (null) for commercial deployments that use SSE-S3 instead. | `string` | `null` | no |
| <a name="input_storage_configuration_name"></a> [storage\_configuration\_name](#input\_storage\_configuration\_name) | Name for the databricks\_mws\_storage\_configurations registration. Should be descriptive and unique within the Databricks account. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the S3 bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 bucket. Useful for downstream IAM policy references. |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | Bucket-regional domain name (e.g. bucket.s3.us-east-1.amazonaws.com). Useful for endpoint configuration. |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the S3 bucket created for workspace root storage (DBFS). |
| <a name="output_databricks_aws_account_id"></a> [databricks\_aws\_account\_id](#output\_databricks\_aws\_account\_id) | Databricks control plane AWS account ID computed from databricks\_gov\_shard. Useful for verification and downstream trust-policy construction. |
| <a name="output_storage_configuration_id"></a> [storage\_configuration\_id](#output\_storage\_configuration\_id) | Databricks storage configuration ID. Pass to workspace creation modules as the storage\_configuration\_id input. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each `databricks_gov_shard` value (null, civilian, dod) produces the correct computed Databricks AWS account ID
- Invalid `aws_partition` is rejected by variable validation
- Invalid `databricks_gov_shard` is rejected by variable validation
- Invalid `bucket_name` (too short, too long, invalid chars) is rejected by variable validation
- Invalid `storage_configuration_name` is rejected by variable validation
- SSE algorithm switches between AES256 and aws:kms based on `kms_key_arn`
- S3 bucket name and public access block attributes are planned correctly

Run with `terraform test` from the module root.

An apply-command integration test (against a real AWS + Databricks account) verifies actual bucket creation and storage configuration registration. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
