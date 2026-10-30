# gcp-uc-storage-bucket

Creates the dedicated GCS bucket for a Unity Catalog catalog's managed storage. Best practice (OKF unity-catalog): catalog data on its own bucket/container — never the workspace root the platform's workspace catalog shares. CREATE side of create-vs-adopt (Rule 8.4); the adopt side passes an existing bucket + path to the composition.

## When to use

- Composing a catalog with dedicated managed storage (the domain-catalog components' default mode).
- You need a UC-ready bucket/container with sane security defaults as a standalone primitive.

## When NOT to use

- The catalog should live on the metastore's default managed storage (no dedicated bucket) — omit the storage wiring instead.
- You already have the bucket — pass it directly to the composition (adopt), don't recreate it.


## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 8.8.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_storage_bucket.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the dedicated GCS bucket for the catalog's managed storage. Globally unique; a common convention is "<catalog-name>-uc" with an org suffix. | `string` | n/a | yes |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow the bucket (and all contained objects) to be destroyed by Terraform. Required for clean teardown of scratch deployments; consider false for long-lived data. | `bool` | `false` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels applied to the bucket. GCP labels: lowercase keys/values, hyphens/underscores allowed. | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | GCS bucket location — a region (e.g. "us-east1"), multi-region (e.g. "US"), or dual-region. Should co-locate with the workspace's metastore. | `string` | `"US"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the dedicated UC bucket. |
| <a name="output_storage_root"></a> [storage\_root](#output\_storage\_root) | The Unity Catalog storage-root URL for this bucket (gs://<bucket>). Append the catalog's path suffix at the composition. |
<!-- END_TF_DOCS -->
