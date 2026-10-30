# aws-uc-storage-bucket

Creates the dedicated S3 bucket for a Unity Catalog catalog's managed storage. Best practice (OKF unity-catalog): catalog data on its own bucket/container — never the workspace root the platform's workspace catalog shares. CREATE side of create-vs-adopt (Rule 8.4); the adopt side passes an existing bucket + path to the composition.

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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.70.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the dedicated S3 bucket for the catalog's managed storage. Globally unique across AWS; a common convention is "<catalog-name>-uc" with an org suffix. | `string` | n/a | yes |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow the bucket (and all contained objects) to be destroyed by Terraform. Required for clean teardown of scratch deployments; consider false for long-lived data. | `bool` | `false` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional KMS key ARN for bucket encryption. Null = SSE-S3 (AES256). | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the dedicated UC bucket. |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the dedicated UC bucket. |
| <a name="output_storage_root"></a> [storage\_root](#output\_storage\_root) | The Unity Catalog storage-root URL for this bucket (s3://<bucket>). Append the catalog's path suffix at the composition. |
<!-- END_TF_DOCS -->
