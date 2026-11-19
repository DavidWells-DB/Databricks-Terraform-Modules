# GCP account encryption keys

Creates one Cloud KMS key ring and symmetric encryption key, plus optional
`roles/cloudkms.cryptoKeyEncrypterDecrypter` bindings. The `crypto_key_id`
output matches the GCP classic workspace Blueprint's `cmk_key_id` input. IAM
members are explicit because the Databricks provisioning and control-plane
identities vary by deployment.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_kms_crypto_key.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key_iam_member.accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_key_ring.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_crypto_key_name"></a> [crypto\_key\_name](#input\_crypto\_key\_name) | Cloud KMS crypto-key creation name. | `string` | n/a | yes |
| <a name="input_key_ring_name"></a> [key\_ring\_name](#input\_key\_ring\_name) | Cloud KMS key-ring creation name. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | KMS location, normally the workspace region. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project for the key ring and crypto key. | `string` | n/a | yes |
| <a name="input_accessor_members"></a> [accessor\_members](#input\_accessor\_members) | IAM members granted roles/cloudkms.cryptoKeyEncrypterDecrypter, for example serviceAccount:provisioner@project.iam.gserviceaccount.com. | `set(string)` | `[]` | no |
| <a name="input_rotation_period"></a> [rotation\_period](#input\_rotation\_period) | Optional automatic rotation period such as 7776000s (90 days). Null disables automatic rotation. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_crypto_key_id"></a> [crypto\_key\_id](#output\_crypto\_key\_id) | Created crypto-key ID for the GCP classic workspace cmk\_key\_id input. |
| <a name="output_crypto_key_name"></a> [crypto\_key\_name](#output\_crypto\_key\_name) | Created crypto-key name. |
| <a name="output_key_ring_id"></a> [key\_ring\_id](#output\_key\_ring\_id) | Created key-ring ID. |
<!-- END_TF_DOCS -->
