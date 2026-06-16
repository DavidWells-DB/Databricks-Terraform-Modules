# aws-workspace-restrictive-root-bucket

Applies a least-privilege S3 bucket policy to a Databricks workspace's root storage bucket AFTER workspace creation. Replaces the broad Databricks-generated policy with a tightened version that scopes writes to workspace-specific paths.

## What this module abstracts

"Lock down the root bucket after workspace creation" — a post-provisioning hardening step. The policy allows read access broadly but restricts write access to workspace-specific paths (`ephemeral/{region}-prod/{workspace_id}/*`, `user/hive/warehouse/*`, `FileStore/*`), enforces principal tag conditions, and denies non-HTTPS access.

## When to use

- You've provisioned a Databricks workspace with a root storage bucket.
- You want to apply least-privilege bucket policies after workspace creation (Databricks generates a permissive policy at workspace creation time).
- Your security posture requires scoped write access and SSL enforcement.

## When NOT to use

- The workspace hasn't been created yet — the root bucket must exist and the workspace must be provisioned before applying this policy.
- You're managing the bucket policy outside of Terraform — this module will conflict with externally managed policies.
- You need custom policy statements beyond the restrictive pattern — fork and modify the `locals.tf` policy construction at the root composition.

## Minimum platform tier

**Premium.** Root bucket policy enforcement is a security feature typically deployed in Premium+ workspaces.

## GovCloud parameterization

The `databricks_gov_shard` input drives the Databricks control plane AWS account ID used in the bucket policy principal:

| Shard | `databricks_gov_shard` | `aws_partition` | Databricks AWS account ID |
|---|---|---|---|
| Commercial | `null` (default) | `"aws"` | `414351767826` |
| GovCloud civilian | `"civilian"` | `"aws-us-gov"` | `044793339203` |
| GovCloud DoD | `"dod"` | `"aws-us-gov"` | `170661010020` |

Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud

## Provider configuration

The module requires only the `aws` provider. No Databricks provider is needed — this is a pure AWS resource operation.

The AWS provider must be configured for the same partition as the `aws_partition` input.

## Workspace-specific path scoping

The policy restricts write access to the following paths:

- `ephemeral/{region}-prod/{workspace_id}/*` — workspace ephemeral storage (logs, cluster init scripts, etc.)
- `user/hive/warehouse/*` — Hive metastore tables (when using the workspace's default metastore)
- `FileStore/*` — DBFS FileStore (user-uploaded files, libraries)

All other paths (e.g., root-level files, other workspace directories) are read-only.

## Principal tag condition

The policy enforces `aws:PrincipalTag/DatabricksAccountId` equals the Databricks account ID. IAM roles assumed by the Databricks control plane must be tagged with `DatabricksAccountId=<account-id>` to access the bucket. This is the standard Databricks cross-account role tagging pattern.

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
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition for ARN construction. Use "aws" for commercial; "aws-us-gov" for GovCloud (both civilian and DoD shards). | `string` | n/a | yes |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the Databricks workspace root storage bucket. | `string` | n/a | yes |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Used in the principal tag condition to restrict access to roles tagged with this account ID. | `string` | n/a | yes |
| <a name="input_databricks_gov_shard"></a> [databricks\_gov\_shard](#input\_databricks\_gov\_shard) | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region where the workspace is deployed. Used to construct the ephemeral path prefix. | `string` | n/a | yes |
| <a name="input_workspace_id"></a> [workspace\_id](#input\_workspace\_id) | Databricks workspace ID. Used to scope write access to workspace-specific ephemeral paths. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the S3 bucket to which the restrictive policy was applied. |
| <a name="output_bucket_policy_id"></a> [bucket\_policy\_id](#output\_bucket\_policy\_id) | S3 bucket policy resource ID (format: bucket\_name). Use in depends\_on when ordering post-workspace policy updates. |
| <a name="output_databricks_aws_account_id"></a> [databricks\_aws\_account\_id](#output\_databricks\_aws\_account\_id) | Databricks control plane AWS account ID used in the bucket policy's principal. Computed from databricks\_gov\_shard. Useful for verification and downstream policy construction. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each `databricks_gov_shard` value (null, civilian, dod) produces the correct computed Databricks AWS account ID
- Invalid `aws_partition` is rejected by variable validation
- Invalid `databricks_gov_shard` is rejected by variable validation
- Invalid `bucket_name`, `workspace_id`, `region`, and `databricks_account_id` formats are rejected
- Policy contains correct path scoping, principal tag condition, and SSL enforcement

Run with `terraform test` from the module root.

An apply-command integration test (against a real AWS + Databricks workspace) verifies actual bucket policy application. It is credential-gated and is added when the test environment is wired.
