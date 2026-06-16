# gcp-uc-storage-credential

Provisions a Databricks Unity Catalog storage credential backed by a Databricks-managed GCP service account and grants that service account the IAM roles required to read and write objects in a target GCS bucket.

## What this module abstracts

"The credential Databricks uses to access GCS on behalf of Unity Catalog" — one indivisible function. The Databricks storage credential registration and the GCP IAM bindings that make it functional are paired per DATABRICKS_RULES.md Rule 1.4: splitting them produces thin wrappers; pairing them produces a real abstraction.

When `databricks_gcp_service_account {}` is declared, Databricks provisions a managed GCP service account automatically. The service account email is not known until after apply; this module wires it to the GCS bucket IAM bindings in the same configuration so the caller never needs to handle that email directly.

## When to use

- You are setting up a Unity Catalog external location or metastore data access on GCP and need a storage credential backed by a Databricks-managed service account.
- You want a single module that creates the Databricks credential AND grants the required GCS IAM roles.

## When NOT to use

- You already have a `databricks_storage_credential` you want to reuse — use a `data` source at the root composition instead.
- You are on AWS or Azure — they use different credential mechanisms (`aws_iam_role` and `azure_managed_identity` respectively).
- Your GCS bucket IAM is managed by a separate team — have that team grant `roles/storage.objectAdmin` and `roles/storage.legacyBucketReader` to the service account email, then pass an existing credential ID to downstream modules.

## Minimum platform tier

**Premium.** Unity Catalog storage credentials require a Premium-tier Databricks workspace. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier workspace, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

The module declares `configuration_aliases = [databricks.workspace]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.workspace` provider configured against the target workspace URL.

The `google` provider must be configured with credentials that have `storage.buckets.setIamPolicy` permission on the target bucket (typically `roles/storage.admin` or a custom role).

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
| <a name="provider_databricks.workspace"></a> [databricks.workspace](#provider\_databricks.workspace) | >= 1.50 |
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_storage_credential.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/storage_credential) | resource |
| [google_storage_bucket_iam_member.bucket_reader](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_iam_member.object_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the GCS bucket to which the Databricks-managed service account is granted storage access. Must be an existing bucket. | `string` | n/a | yes |
| <a name="input_comment"></a> [comment](#input\_comment) | Optional free-text comment for the storage credential. Visible in the Databricks UI and API. | `string` | `null` | no |
| <a name="input_credential_name"></a> [credential\_name](#input\_credential\_name) | Name of the Databricks Unity Catalog storage credential. Must be unique within the metastore. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_databricks_service_account_email"></a> [databricks\_service\_account\_email](#output\_databricks\_service\_account\_email) | Email address of the Databricks-managed GCP service account. Use this to grant additional GCP IAM permissions beyond the default bucket access. |
| <a name="output_storage_credential_id"></a> [storage\_credential\_id](#output\_storage\_credential\_id) | Databricks Unity Catalog storage credential ID. Pass to databricks\_external\_location or databricks\_metastore\_data\_access as the storage\_credential\_name input. |
| <a name="output_storage_credential_name"></a> [storage\_credential\_name](#output\_storage\_credential\_name) | Name of the Databricks Unity Catalog storage credential, as registered in the metastore. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid inputs produce correctly named resources
- `credential_name` validation rejects empty strings and names with spaces
- `bucket_name` validation rejects names that are too short, too long, or contain uppercase letters
- Storage credential and IAM member resources are planned with expected attributes

Run with `terraform test` from the module root.

An apply-command integration test (against a real GCP project + Databricks workspace) verifies actual credential creation and IAM binding. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
