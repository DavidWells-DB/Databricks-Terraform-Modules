# aws-uc-storage-credential

Creates the AWS IAM role for Unity Catalog storage access and registers it as a `databricks_storage_credential` in Unity Catalog.

## What this module abstracts

"The storage credential Databricks UC uses to read/write an S3 bucket" — one indivisible function. The AWS IAM role (trust policy + S3 access policy) and its Databricks-side registration are paired per DATABRICKS_RULES.md Rule 1.4: splitting them produces thin wrappers; pairing them produces a real abstraction.

## When to use

- You're registering a new S3 bucket with Unity Catalog as an external location or metastore root storage.
- You want a single module that creates the AWS IAM role AND registers it as a Databricks UC storage credential.
- The workspace already has a Unity Catalog metastore assigned.

## When NOT to use

- You already have a `databricks_storage_credential` you want to reuse — use a `data` source at the root composition instead.
- You're on Azure (use an Access Connector module) or GCP (use a GCP service account module).
- Your IAM role is managed by a separate team — create the storage credential directly in the root composition using the existing role ARN.

## Minimum platform tier

**Premium.** Unity Catalog requires Premium tier. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier workspace, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Dependency ordering and the external_id pattern

AWS IAM trust policies for Unity Catalog require a `databricks`-generated `external_id` to prevent the [confused deputy problem](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html). This creates an apparent circular dependency:

- `databricks_storage_credential` needs the IAM role ARN (to register it).
- `aws_iam_role` trust policy needs `external_id` (from `databricks_storage_credential`).

This module resolves the dependency by pre-computing the IAM role ARN from `aws_account_id` + `role_name` + `aws_partition`. Because the ARN is deterministic before the role exists, Terraform can create `databricks_storage_credential` first (`skip_validation = true`), extract the `external_id`, and then create `aws_iam_role` with the correct trust policy.

On the second apply (and all subsequent applies), `skip_validation` has no effect — Databricks validates the trust relationship on every read, and the IAM role is live.

## GovCloud parameterization

The `databricks_gov_shard` input drives the Databricks Unity Catalog master role ARN used in the IAM trust policy:

| Shard | `databricks_gov_shard` | `aws_partition` | Databricks UC master role |
|---|---|---|---|
| Commercial | `null` (default) | `"aws"` | `arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL` |
| GovCloud civilian | `"civilian"` | `"aws-us-gov"` | `arn:aws-us-gov:iam::044793339203:role/unity-catalog-prod-UCMasterRole-1QRFA8SGY15OJ` |
| GovCloud DoD | `"dod"` | `"aws-us-gov"` | `arn:aws-us-gov:iam::170661010020:role/unity-catalog-prod-UCMasterRole-1DI6DL6ZP26AS` |

Source: `databricks_aws_unity_catalog_assume_role_policy` provider documentation and DATABRICKS_RULES.md Rule 1.5.

## Provider configuration

This module declares `configuration_aliases = [databricks.workspace]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.workspace` provider configured against the workspace URL.

The `databricks_aws_unity_catalog_assume_role_policy` and `databricks_aws_unity_catalog_policy` data sources work with both account-level and workspace-level providers; this module uses the workspace provider throughout for consistency.

The AWS provider must be configured for the same partition as the `aws_partition` input.

## Race condition handled

The module includes a `time_sleep` resource (30s) between IAM role policy attachment and any Databricks operation that validates the trust relationship. Without this delay, Databricks may fail when the IAM role has not yet propagated through AWS globally. The delay is a sanctioned use of `time_sleep` per DATABRICKS_RULES.md Rule 3.1.

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
| <a name="provider_databricks.workspace"></a> [databricks.workspace](#provider\_databricks.workspace) | >= 1.50 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.9 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [databricks_storage_credential.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/storage_credential) | resource |
| [time_sleep.iam_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [databricks_aws_unity_catalog_assume_role_policy.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/data-sources/aws_unity_catalog_assume_role_policy) | data source |
| [databricks_aws_unity_catalog_policy.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/data-sources/aws_unity_catalog_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS account ID where the IAM role is created. Used to construct the role ARN for the storage credential and to scope the trust policy. | `string` | n/a | yes |
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition for ARN construction. Use "aws" for commercial; "aws-us-gov" for GovCloud (both civilian and DoD shards). | `string` | n/a | yes |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket that this storage credential grants access to. Used to generate the scoped S3 IAM policy via databricks\_aws\_unity\_catalog\_policy. | `string` | n/a | yes |
| <a name="input_comment"></a> [comment](#input\_comment) | Optional human-readable description for the Databricks storage credential. | `string` | `null` | no |
| <a name="input_credential_name"></a> [credential\_name](#input\_credential\_name) | Name of the Databricks UC storage credential. Must be unique within the metastore. | `string` | n/a | yes |
| <a name="input_databricks_gov_shard"></a> [databricks\_gov\_shard](#input\_databricks\_gov\_shard) | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. Drives the Unity Catalog IAM ARN used in the trust policy. | `string` | `null` | no |
| <a name="input_isolation_mode"></a> [isolation\_mode](#input\_isolation\_mode) | Isolation mode for the storage credential. "ISOLATION\_MODE\_ISOLATED" restricts the credential to its owning metastore; "ISOLATION\_MODE\_OPEN" makes it accessible to all metastores. Defaults to "ISOLATION\_MODE\_OPEN". | `string` | `"ISOLATION_MODE_OPEN"` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional ARN of a KMS key used to encrypt the S3 bucket. When provided, the generated IAM policy includes kms:GenerateDataKey* and kms:Decrypt permissions. Omit (null) if the bucket uses SSE-S3 or no encryption. | `string` | `null` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of the AWS IAM role created for Unity Catalog storage access. Must be unique within the AWS account. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the AWS IAM role. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_external_id"></a> [external\_id](#output\_external\_id) | Databricks-generated external ID embedded in the IAM role trust policy. Useful for auditing the confused-deputy protection on the trust relationship. |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the AWS IAM role created for Unity Catalog storage access. |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the AWS IAM role created for Unity Catalog storage access. |
| <a name="output_storage_credential_id"></a> [storage\_credential\_id](#output\_storage\_credential\_id) | Unique ID of the Databricks Unity Catalog storage credential. Use this when referencing the credential in external location or metastore data access resources. |
| <a name="output_storage_credential_name"></a> [storage\_credential\_name](#output\_storage\_credential\_name) | Name of the Databricks Unity Catalog storage credential. |
| <a name="output_unity_catalog_iam_arn"></a> [unity\_catalog\_iam\_arn](#output\_unity\_catalog\_iam\_arn) | Databricks Unity Catalog master role ARN used in the IAM trust policy. Computed from databricks\_gov\_shard. Useful for verification and downstream policy auditing. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each `databricks_gov_shard` value (null, civilian, dod) produces the correct Unity Catalog IAM ARN
- Invalid `aws_partition` is rejected by variable validation
- Invalid `databricks_gov_shard` is rejected by variable validation
- Invalid `aws_account_id` (non-12-digit) is rejected
- Invalid `bucket_name` (too short, bad chars) is rejected
- Invalid `isolation_mode` is rejected
- `role_name` too long or with invalid chars is rejected
- `credential_name` empty or with invalid chars is rejected
- IAM role and storage credential resources are planned with expected attributes

Run with `terraform test` from the module root.

An apply-command integration test (against real AWS + Databricks UC workspace) verifies actual IAM role creation and storage credential registration. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
