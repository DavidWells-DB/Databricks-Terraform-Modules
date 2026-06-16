# gcp-account-workspace-storage

Creates a GCS bucket for Databricks workspace root storage with the required IAM bindings for the Databricks-managed service account, and registers it as a Databricks storage configuration via `databricks_mws_storage_configurations`.

## What this module abstracts

"The storage Databricks uses to manage this workspace's root data" — one indivisible function. The GCS bucket, its IAM bindings, and its Databricks-side registration are paired per DATABRICKS_RULES.md Rule 1.4: splitting them produces thin wrappers; pairing them produces a real abstraction.

## When to use

- You are provisioning a new GCP-hosted Databricks workspace and need to provide root cloud storage.
- You want a single module that creates the GCS bucket, grants the Databricks service account the required IAM roles, AND registers it as a `databricks_mws_storage_configurations` object.

## When NOT to use

- You already have a `databricks_mws_storage_configurations` object you want to reuse — use a `data` source at the root composition instead.
- You are on AWS or Azure — they use different storage mechanisms (`aws-account-workspace-credentials` and Azure Access Connector modules respectively).
- Your GCS bucket is managed by a separate team — look up the existing bucket via `data "google_storage_bucket"` at the root composition, bind the IAM manually, and reference the bucket name directly in a `databricks_mws_storage_configurations` resource.

## Minimum platform tier

**Premium.** `databricks_mws_storage_configurations` is an account-level Workspace API resource available only on Premium and above. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account host (`https://accounts.gcp.databricks.com`).

The `google` provider must be configured for the same GCP project and region as the inputs.

## IAM bindings

Two IAM bindings are applied to the bucket using `google_storage_bucket_iam_member` (additive, no replacement of existing policy):

| Role | Purpose |
|---|---|
| `roles/storage.objectAdmin` | Read/write workspace data objects |
| `roles/storage.legacyBucketReader` | List bucket and read metadata |

The `databricks_service_account_email` input receives both bindings. This is the Databricks-managed GCP service account provided during workspace provisioning.

## CMEK (Customer-Managed Encryption Keys)

Pass a fully-qualified KMS key resource name to `kms_key_name` to enable CMEK encryption on the bucket. When `kms_key_name` is `null` (the default), Google-managed encryption is used.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.50 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | >= 1.50 |
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_mws_storage_configurations.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_storage_configurations) | resource |
| [google_storage_bucket.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.legacy_bucket_reader](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_iam_member.object_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Used in the databricks\_mws\_storage\_configurations registration. | `string` | n/a | yes |
| <a name="input_databricks_service_account_email"></a> [databricks\_service\_account\_email](#input\_databricks\_service\_account\_email) | Email address of the Databricks-managed GCP service account that will be granted IAM access to the bucket. Provided by Databricks during workspace setup (format: service-account@<project>.iam.gserviceaccount.com). | `string` | n/a | yes |
| <a name="input_kms_key_name"></a> [kms\_key\_name](#input\_kms\_key\_name) | Optional Cloud KMS key resource name for server-side encryption of bucket contents (format: projects/<project>/locations/<location>/keyRings/<keyRing>/cryptoKeys/<key>). null disables CMEK and uses Google-managed encryption. | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels applied to the GCS bucket. | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID in which the GCS bucket will be created. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the GCS bucket (e.g. "us-central1"). Must match the region of the Databricks workspace. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix applied to the GCS bucket name and the Databricks storage configuration name. Must be 1-38 characters; lowercase letters, digits, and hyphens only. GCS bucket names have a 63-character limit; the module appends "-root-storage" (13 chars), leaving 50 for the prefix. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the GCS bucket used as workspace root storage. |
| <a name="output_bucket_self_link"></a> [bucket\_self\_link](#output\_bucket\_self\_link) | Self-link URI of the GCS bucket. Useful for referencing the bucket in other Google Cloud resources. |
| <a name="output_bucket_url"></a> [bucket\_url](#output\_bucket\_url) | GCS URL of the root storage bucket (gs://<bucket-name>). |
| <a name="output_storage_configuration_id"></a> [storage\_configuration\_id](#output\_storage\_configuration\_id) | Databricks storage configuration ID. Pass to workspace creation modules as the storage\_configuration\_id input. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Bucket name is computed correctly from `resource_prefix`
- `resource_prefix` validation rejects invalid patterns (too long, invalid chars, leading/trailing hyphens)
- `databricks_service_account_email` validation rejects non-service-account emails
- `kms_key_name` validation rejects malformed KMS key paths
- IAM member resources use the correct roles and service account email
- `databricks_mws_storage_configurations` is planned with the expected bucket name and account ID

Run with `terraform test` from the module root.

An apply-command integration test (against a real GCP project + Databricks account) verifies actual bucket creation and storage configuration registration. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
