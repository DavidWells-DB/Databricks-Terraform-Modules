# aws-account-log-delivery

Creates the AWS S3 bucket and IAM role required for Databricks log delivery, registers them with the Databricks account API, and configures one `databricks_mws_log_delivery` delivery record per requested log type (`AUDIT_LOGS`, `BILLABLE_USAGE`, or both).

## What this module abstracts

"The log delivery pipeline Databricks uses to ship audit and usage data to customer-owned S3." The S3 bucket, its public access block and bucket policy, the IAM role that Databricks assumes to write to the bucket, the Databricks credentials registration, the Databricks storage configuration registration, and the log delivery configurations all form one indivisible function. Splitting them produces thin wrappers; pairing them produces a real abstraction (DATABRICKS_RULES.md Rule 1.4).

## When to use

- You're bootstrapping a new AWS-hosted Databricks account (commercial, GovCloud civilian, or GovCloud DoD) and want Databricks to deliver audit logs and/or billable usage logs to S3.
- You need a single module that provisions both the AWS infrastructure (S3, IAM) and the Databricks-side registrations in one apply.

## When NOT to use

- You already have an S3 bucket and IAM role and want to register them with Databricks — configure the Databricks resources directly in the root composition using `data` sources for the existing AWS resources.
- You're on Azure or GCP — those platforms use different log delivery mechanisms.
- You only want to manage the Databricks log delivery configuration and already have all AWS infrastructure — use `databricks_mws_log_delivery` directly in the root composition.

## Minimum platform tier

**Premium.** The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## GovCloud parameterization

The `databricks_gov_shard` input drives the Databricks control plane AWS account ID used in the IAM role trust policy, and `aws_partition` drives ARN construction:

| Shard | `databricks_gov_shard` | `aws_partition` | Databricks AWS account ID |
|---|---|---|---|
| Commercial | `null` (default) | `"aws"` | `414351767826` |
| GovCloud civilian | `"civilian"` | `"aws-us-gov"` | `044793339203` |
| GovCloud DoD | `"dod"` | `"aws-us-gov"` | `170661010020` |

Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud

GovCloud note: Audit logging is a compliance requirement in GovCloud environments. `log_types` defaults to `["AUDIT_LOGS", "BILLABLE_USAGE"]` — do not remove `AUDIT_LOGS` in GovCloud deployments.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account host:

| Shard | Account host |
|---|---|
| Commercial | `https://accounts.cloud.databricks.com` |
| GovCloud civilian | `https://accounts.cloud.databricks.us` |
| GovCloud DoD | `https://accounts-dod.cloud.databricks.mil` |

The AWS provider must be configured for the same partition as the `aws_partition` input.

## Race condition handled

The module includes a `time_sleep` resource (30s) between IAM role creation and the `databricks_mws_credentials` registration. Without this delay, `databricks_mws_credentials` can fail when the IAM role hasn't fully propagated through AWS global IAM. This is a sanctioned use of `time_sleep` per DATABRICKS_RULES.md Rule 3.1.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.50 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | >= 1.50 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.9 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [databricks_mws_credentials.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_credentials) | resource |
| [databricks_mws_log_delivery.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_log_delivery) | resource |
| [databricks_mws_storage_configurations.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_storage_configurations) | resource |
| [time_sleep.iam_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [databricks_aws_assume_role_policy.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/data-sources/aws_assume_role_policy) | data source |
| [databricks_aws_bucket_policy.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/data-sources/aws_bucket_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition for ARN construction. Use "aws" for commercial; "aws-us-gov" for GovCloud (both civilian and DoD shards). | `string` | n/a | yes |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Used as the external ID in the IAM role's assume-role policy and in the storage configuration registration. | `string` | n/a | yes |
| <a name="input_databricks_gov_shard"></a> [databricks\_gov\_shard](#input\_databricks\_gov\_shard) | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days after which log objects in the S3 bucket are expired. Must be at least 1. Defaults to 365 days. | `number` | `365` | no |
| <a name="input_log_types"></a> [log\_types](#input\_log\_types) | Log types to configure delivery for. Valid values: "AUDIT\_LOGS" (workspace audit events), "BILLABLE\_USAGE" (DBU consumption). Defaults to both. Each value creates one databricks\_mws\_log\_delivery configuration. | `list(string)` | <pre>[<br/>  "AUDIT_LOGS",<br/>  "BILLABLE_USAGE"<br/>]</pre> | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix applied to all AWS and Databricks resource names created by this module (S3 bucket, IAM role, credentials, storage configuration, log delivery config). Must be 1-32 characters, alphanumeric, hyphens, or underscores. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all AWS resources created by this module (S3 bucket, IAM role). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 bucket that receives Databricks log files. |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the S3 bucket that receives Databricks log files. |
| <a name="output_credentials_id"></a> [credentials\_id](#output\_credentials\_id) | Databricks credentials object ID for the log delivery IAM role. |
| <a name="output_databricks_aws_account_id"></a> [databricks\_aws\_account\_id](#output\_databricks\_aws\_account\_id) | Databricks control plane AWS account ID used in the IAM role trust policy. Computed from databricks\_gov\_shard. Useful for verification and downstream policy construction. |
| <a name="output_log_delivery_configuration_ids"></a> [log\_delivery\_configuration\_ids](#output\_log\_delivery\_configuration\_ids) | Map of log\_type to databricks\_mws\_log\_delivery configuration ID (e.g. { AUDIT\_LOGS = "...", BILLABLE\_USAGE = "..." }). |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the AWS IAM role used by Databricks to write log files to the S3 bucket. |
| <a name="output_storage_configuration_id"></a> [storage\_configuration\_id](#output\_storage\_configuration\_id) | Databricks storage configuration ID for the log delivery S3 bucket. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each `databricks_gov_shard` value (null, civilian, dod) produces the correct computed Databricks AWS account ID
- Invalid `aws_partition` is rejected by variable validation
- Invalid `databricks_gov_shard` is rejected by variable validation
- Invalid `log_types` values are rejected by variable validation
- Empty `log_types` list is rejected by variable validation
- Invalid `resource_prefix` (too long, invalid characters) is rejected by variable validation
- S3 bucket name, IAM role name, and Databricks resource names use the `resource_prefix`
- `for_each` on `log_types` produces one `databricks_mws_log_delivery` per type

Run with `terraform test` from the module root.

An apply-command integration test (against a real AWS + Databricks account) verifies actual S3 bucket and IAM role creation and log delivery configuration. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
