# dbx-uc-metastore

Creates a Unity Catalog metastore and sets its default data access credential via `databricks_metastore_data_access`.

## What this module abstracts

"The metastore" — the top-level Unity Catalog namespace for a Databricks account in a given region. One metastore per account per region. The module pairs `databricks_metastore` (the namespace itself) with `databricks_metastore_data_access` (the default credential Databricks uses to read/write managed table data) because neither resource is useful without the other.

## When to use

- You are setting up Unity Catalog for the first time in a region.
- You want a single module that creates the metastore AND wires up its default storage credential.

## When NOT to use

- A metastore already exists in the region — you cannot create a second one per account. Use a `data "databricks_metastore"` source at the root composition instead.
- You need to assign the metastore to workspaces — that is a separate operation handled by the `dbx-uc-metastore-assignment` module.
- You need to create additional external locations or storage credentials beyond the default — use `dbx-uc-external-location` and manage `databricks_storage_credential` resources separately.

## Minimum platform tier

**Premium.** Unity Catalog (and therefore `databricks_metastore`) requires the Premium or Enterprise tier. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account host:

| Cloud     | Account host URL                                          |
|-----------|-----------------------------------------------------------|
| AWS       | `https://accounts.cloud.databricks.com`                   |
| Azure     | `https://accounts.azuredatabricks.net`                    |
| GCP       | `https://accounts.gcp.databricks.com`                     |

This module is **cloud-agnostic** at the Databricks provider level. Cloud-specific differences are expressed through the `storage_credential` input (see below).

## Storage credential input

The `storage_credential` variable follows DATABRICKS_RULES.md Rule 2.4 (cloud credential as object-typed input). Populate exactly one cloud-specific block:

```hcl
# AWS
storage_credential = {
  aws_iam_role = {
    role_arn = "arn:aws:iam::123456789012:role/my-uc-role"
  }
}

# Azure
storage_credential = {
  azure_managed_identity = {
    access_connector_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Databricks/accessConnectors/my-connector"
  }
}

# GCP (uses Databricks-managed GCS service account)
storage_credential = {
  databricks_gcp_service_account = {}
}
```

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.50 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | >= 1.50 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_metastore.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/metastore) | resource |
| [databricks_metastore_data_access.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/metastore_data_access) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_data_access_name"></a> [data\_access\_name](#input\_data\_access\_name) | Name for the default data access configuration (databricks\_metastore\_data\_access). Typically matches the storage credential or IAM role name. | `string` | n/a | yes |
| <a name="input_metastore_name"></a> [metastore\_name](#input\_metastore\_name) | Display name for the Unity Catalog metastore. Must be unique within the Databricks account. | `string` | n/a | yes |
| <a name="input_owner_group"></a> [owner\_group](#input\_owner\_group) | Databricks account-level group that owns the metastore. Defaults to the creating principal if not set. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Cloud region where the metastore is created. Must match the region of any workspaces you intend to assign. One metastore per account per region. | `string` | n/a | yes |
| <a name="input_storage_credential"></a> [storage\_credential](#input\_storage\_credential) | Storage credential for the metastore default data access. Populate exactly one cloud-specific block: aws\_iam\_role for AWS, azure\_managed\_identity for Azure, or databricks\_gcp\_service\_account for GCP. Per DATABRICKS\_RULES.md Rule 2.4. | <pre>object({<br/>    aws_iam_role = optional(object({<br/>      role_arn = string<br/>    }))<br/>    azure_managed_identity = optional(object({<br/>      access_connector_id = string<br/>      managed_identity_id = optional(string)<br/>    }))<br/>    databricks_gcp_service_account = optional(object({}))<br/>  })</pre> | n/a | yes |
| <a name="input_storage_root_url"></a> [storage\_root\_url](#input\_storage\_root\_url) | Cloud storage URL for the metastore root. On AWS: s3://bucket-name/optional-prefix. On Azure: abfss://container@account.dfs.core.windows.net/optional-prefix. On GCP: gs://bucket-name/optional-prefix. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_data_access_id"></a> [data\_access\_id](#output\_data\_access\_id) | ID of the databricks\_metastore\_data\_access resource in format <metastore\_id>\|<name>. Useful for verification and downstream references. |
| <a name="output_metastore_id"></a> [metastore\_id](#output\_metastore\_id) | The globally unique ID of the Unity Catalog metastore. Pass to workspace assignment modules as the metastore\_id input. |
| <a name="output_metastore_name"></a> [metastore\_name](#output\_metastore\_name) | Display name of the Unity Catalog metastore. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Invalid `storage_root_url` schemes are rejected by variable validation.
- Invalid `region` format is rejected by variable validation.
- Empty `metastore_name` is rejected by variable validation.
- Metastore name with leading/trailing whitespace is rejected.
- Setting more than one storage credential block simultaneously is rejected.
- Setting no storage credential block is rejected.
- Metastore resource is planned with expected `name`, `region`, and `storage_root` attributes.
- Data access resource is planned with `is_default = true`.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks account) verifies actual metastore creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
