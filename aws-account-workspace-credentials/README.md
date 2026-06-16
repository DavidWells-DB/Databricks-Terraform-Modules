# aws-account-workspace-credentials

Creates the AWS IAM cross-account role granting the Databricks control plane permission to manage compute (EC2, VPC, EBS) resources in the customer AWS account, and registers it as a Databricks credentials object via `databricks_mws_credentials`.

## What this module abstracts

"The credentials Databricks uses to manage this workspace's compute" — one indivisible function. The AWS IAM role and its Databricks-side registration are paired per DATABRICKS_RULES.md Rule 1.4: splitting them produces thin wrappers; pairing them produces a real abstraction.

## When to use

- You're provisioning a new AWS-hosted Databricks workspace (commercial, GovCloud civilian, or GovCloud DoD).
- You want a single module that creates the IAM role AND registers it as Databricks credentials.

## When NOT to use

- You already have a `databricks_mws_credentials` object you want to reuse — use a `data` source at the root composition instead.
- You're on Azure or GCP — they use different credential mechanisms.
- Your AWS IAM role is managed by a separate team — at the root composition, look up the existing role via `data "aws_iam_role"` and pass its ARN to a `databricks_mws_credentials` resource directly.

## Minimum platform tier

**Premium.** The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## GovCloud parameterization

The `databricks_gov_shard` input drives the Databricks control plane AWS account ID used in the cross-account trust policy:

| Shard | `databricks_gov_shard` | `aws_partition` | Databricks AWS account ID |
|---|---|---|---|
| Commercial | `null` (default) | `"aws"` | `414351767826` |
| GovCloud civilian | `"civilian"` | `"aws-us-gov"` | `044793339203` |
| GovCloud DoD | `"dod"` | `"aws-us-gov"` | `170661010020` |

Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account host (`https://accounts.cloud.databricks.com` for commercial, `https://accounts.cloud.databricks.us` for GovCloud civilian, `https://accounts-dod.cloud.databricks.mil` for GovCloud DoD).

The AWS provider must be configured for the same partition as the `aws_partition` input.

## Race condition handled

The module includes a `time_sleep` resource (30s) between IAM role creation and `databricks_mws_credentials` registration. Without this delay, `databricks_mws_credentials` can fail when the IAM role hasn't fully propagated through AWS. The delay is a sanctioned use of `time_sleep` per DATABRICKS_RULES.md Rule 3.1.

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
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [databricks_mws_credentials.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_credentials) | resource |
| [time_sleep.iam_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [databricks_aws_assume_role_policy.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/data-sources/aws_assume_role_policy) | data source |
| [databricks_aws_crossaccount_policy.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/data-sources/aws_crossaccount_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition for ARN construction. Use "aws" for commercial; "aws-us-gov" for GovCloud (both civilian and DoD shards). | `string` | n/a | yes |
| <a name="input_credentials_name"></a> [credentials\_name](#input\_credentials\_name) | Name for the databricks\_mws\_credentials registration. Should be descriptive and unique within the Databricks account. | `string` | n/a | yes |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Used as the external ID in the AWS IAM role's assume-role policy. | `string` | n/a | yes |
| <a name="input_databricks_gov_shard"></a> [databricks\_gov\_shard](#input\_databricks\_gov\_shard) | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. | `string` | `null` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of the AWS IAM cross-account role. Must be unique within the AWS account. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the AWS IAM role. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_credentials_id"></a> [credentials\_id](#output\_credentials\_id) | Databricks credentials object ID. Pass to workspace creation modules as the credentials\_id input. |
| <a name="output_databricks_aws_account_id"></a> [databricks\_aws\_account\_id](#output\_databricks\_aws\_account\_id) | Databricks control plane AWS account ID used in the role's trust policy. Computed from databricks\_gov\_shard. Useful for verification and downstream policy construction. |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the AWS IAM cross-account role. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the AWS IAM cross-account role. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each `databricks_gov_shard` value (null, civilian, dod) produces the correct computed Databricks AWS account ID
- Invalid `aws_partition` is rejected by variable validation
- Invalid `databricks_gov_shard` is rejected by variable validation
- IAM role and credentials registration resources are planned with expected attributes

Run with `terraform test` from the module root.

An apply-command integration test (against a real AWS + Databricks account) verifies actual IAM role creation and credentials registration. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
