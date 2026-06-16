# aws-account-encryption-keys

Creates customer-managed KMS keys for Databricks workspace encryption on AWS, and registers them as Databricks customer-managed key (CMK) configurations via `databricks_mws_customer_managed_keys`. Two keys are created:

1. **Managed-services key** — encrypts workspace objects stored in the Databricks control plane: notebooks, secrets, Databricks SQL queries, and SQL query history.
2. **Workspace-storage key** — encrypts the workspace root S3 bucket (DBFS) and cluster EBS volumes.

## What this module abstracts

"The encryption keys Databricks uses for this workspace" — an indivisible function. Each AWS KMS key and its Databricks-side registration are paired per DATABRICKS_RULES.md Rule 1.4: splitting them produces thin wrappers; pairing them produces a real abstraction.

## When to use

- You're provisioning a new AWS-hosted Databricks workspace and need customer-managed encryption at rest.
- You want a single module that creates both KMS keys AND registers them as Databricks CMK configurations.
- You're in a GovCloud environment where CMK is required.

## When NOT to use

- You already have existing KMS keys and want to reuse them — use `data "aws_kms_key"` at the root composition and create `databricks_mws_customer_managed_keys` resources directly.
- You're on Azure or GCP — they use different key management mechanisms.
- You only need one of the two use cases (managed services or storage). In that case, author the single `databricks_mws_customer_managed_keys` resource directly at the root composition.

## Minimum platform tier

**Premium.** CMK registration via `databricks_mws_customer_managed_keys` requires a Premium account. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## GovCloud parameterization

The `databricks_gov_shard` input drives the Databricks control plane AWS account ID embedded in both KMS key policies:

| Shard | `databricks_gov_shard` | `aws_partition` | Databricks AWS account ID |
|---|---|---|---|
| Commercial | `null` (default) | `"aws"` | `414351767826` |
| GovCloud civilian | `"civilian"` | `"aws-us-gov"` | `044793339203` |
| GovCloud DoD | `"dod"` | `"aws-us-gov"` | `170661010020` |

Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud

GovCloud workspaces require CMK; this module is therefore mandatory in GovCloud deployments.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account host:

| Shard | Account host |
|---|---|
| Commercial | `https://accounts.cloud.databricks.com` |
| GovCloud civilian | `https://accounts.cloud.databricks.us` |
| GovCloud DoD | `https://accounts-dod.cloud.databricks.mil` |

The AWS provider must be configured for the same partition as the `aws_partition` input.

## Key policy design

Both KMS key policies follow the pattern from the official Databricks documentation:

- The customer account root is granted full `kms:*` permissions for key administration.
- The Databricks control plane account is granted the permissions required for its use case (encrypt/decrypt for managed services; encrypt/decrypt/grants for DBFS; create-grant for EBS).
- For the workspace-storage key, the `cross_account_role_arn` is added so that EC2 instances launched by the workspace can use the key for EBS volume encryption.

Both keys have automatic rotation enabled and a 7-day deletion window.

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
| [aws_kms_alias.managed_services](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.workspace_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.managed_services](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.workspace_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [databricks_mws_customer_managed_keys.managed_services](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_customer_managed_keys) | resource |
| [databricks_mws_customer_managed_keys.workspace_storage](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_customer_managed_keys) | resource |
| [aws_iam_policy_document.managed_services](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.workspace_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS account ID of the customer account. Used in KMS key policies to grant the account root full key administration. | `string` | n/a | yes |
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition for ARN construction. Use "aws" for commercial; "aws-us-gov" for GovCloud (both civilian and DoD shards). | `string` | n/a | yes |
| <a name="input_cross_account_role_arn"></a> [cross\_account\_role\_arn](#input\_cross\_account\_role\_arn) | ARN of the Databricks cross-account IAM role. Added to the storage key policy so EBS volumes on workspace clusters can use the key. | `string` | n/a | yes |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Used as the account\_id field on both databricks\_mws\_customer\_managed\_keys resources. | `string` | n/a | yes |
| <a name="input_databricks_gov_shard"></a> [databricks\_gov\_shard](#input\_databricks\_gov\_shard) | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. | `string` | `null` | no |
| <a name="input_managed_services_key_alias"></a> [managed\_services\_key\_alias](#input\_managed\_services\_key\_alias) | AWS KMS alias for the managed-services CMK (notebooks, secrets, SQL history). Must start with "alias/". | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to both AWS KMS keys. | `map(string)` | `{}` | no |
| <a name="input_workspace_storage_key_alias"></a> [workspace\_storage\_key\_alias](#input\_workspace\_storage\_key\_alias) | AWS KMS alias for the workspace-storage CMK (DBFS root bucket, cluster EBS volumes). Must start with "alias/". | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_databricks_control_plane_aws_account_id"></a> [databricks\_control\_plane\_aws\_account\_id](#output\_databricks\_control\_plane\_aws\_account\_id) | Databricks control plane AWS account ID used in KMS key policies. Derived from databricks\_gov\_shard. Useful for verification and downstream policy construction. |
| <a name="output_managed_services_key_alias"></a> [managed\_services\_key\_alias](#output\_managed\_services\_key\_alias) | Name of the AWS KMS alias for the managed-services key. |
| <a name="output_managed_services_key_arn"></a> [managed\_services\_key\_arn](#output\_managed\_services\_key\_arn) | ARN of the AWS KMS key used for managed-services encryption. |
| <a name="output_managed_services_key_id"></a> [managed\_services\_key\_id](#output\_managed\_services\_key\_id) | Databricks CMK object ID for managed services. Pass as managed\_services\_customer\_managed\_key\_id to workspace creation modules. |
| <a name="output_workspace_storage_key_alias"></a> [workspace\_storage\_key\_alias](#output\_workspace\_storage\_key\_alias) | Name of the AWS KMS alias for the workspace-storage key. |
| <a name="output_workspace_storage_key_arn"></a> [workspace\_storage\_key\_arn](#output\_workspace\_storage\_key\_arn) | ARN of the AWS KMS key used for workspace-storage encryption (DBFS, EBS). |
| <a name="output_workspace_storage_key_id"></a> [workspace\_storage\_key\_id](#output\_workspace\_storage\_key\_id) | Databricks CMK object ID for workspace storage. Pass as storage\_customer\_managed\_key\_id to workspace creation modules. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each `databricks_gov_shard` value (null, civilian, dod) produces the correct Databricks control plane AWS account ID in computed locals
- Invalid `aws_partition` is rejected by variable validation
- Invalid `databricks_gov_shard` is rejected by variable validation
- Invalid `aws_account_id` (non-12-digit) is rejected by variable validation
- Invalid `cross_account_role_arn` format is rejected by variable validation
- Invalid `managed_services_key_alias` (missing "alias/" prefix) is rejected
- Invalid `workspace_storage_key_alias` (missing "alias/" prefix) is rejected
- KMS key and alias resources are planned with expected attributes

Run with `terraform test` from the module root.

An apply-command integration test (against a real AWS + Databricks Premium account) verifies actual KMS key creation and CMK registration. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
