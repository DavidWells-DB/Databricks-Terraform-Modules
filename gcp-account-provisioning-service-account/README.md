# gcp-account-provisioning-service-account

Creates a GCP service account with a custom IAM role granting the minimum permissions required for Databricks workspace provisioning (compute, KMS, GKE, Shared VPC), and registers it as a Databricks account admin via `databricks_user` and `databricks_user_role`.

## What this module abstracts

"The identity Databricks uses to provision GCP workspaces" — one indivisible function. The GCP service account, its custom IAM role, the project IAM binding, and the Databricks account admin registration are paired per DATABRICKS_RULES.md Rule 1.4: splitting them produces thin wrappers; pairing them produces a real abstraction.

## When to use

- You're bootstrapping a new GCP-hosted Databricks account and need a provisioner service account.
- You want a single module that creates the GCP identity AND registers it with Databricks.
- You need to grant one or more operators/pipelines the ability to impersonate the service account during bootstrapping (`delegate_emails`).

## When NOT to use

- You already have a GCP service account you want to reuse — at the root composition, use a `data "google_service_account"` source and pass its email to `databricks_user`/`databricks_user_role` directly.
- You're on AWS or Azure — they use different credential mechanisms.
- You need a workspace-level service principal (not an account admin).

## Minimum platform tier

**Premium.** The `databricks_user_role` resource (assigning `account_admin`) requires a Databricks Premium or Enterprise account. The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject and the apply will fail. See DATABRICKS_RULES.md Rules 2.3 and 4.1.

## Provider configuration

This module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks GCP account host (`https://accounts.gcp.databricks.com`).

The `google` provider must be configured for the GCP project that matches `project_id`.

## Permissions created

The custom role grants the service account these permission groups:

| Group | Purpose |
|---|---|
| `compute.*` | Manage instances, disks, firewalls, and networks for workspace nodes |
| `cloudkms.*` | Encrypt/decrypt workspace storage when customer-managed keys are used |
| `container.*` | Create and manage GKE clusters and node pools |
| `compute.subnetworks.*IAMPolicy` | Use Shared VPC subnets from a host project |
| `iam.serviceAccounts.*` | Bind node service accounts to GKE node pools |
| `serviceusage.*` | Verify enabled APIs |

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
| [databricks_user.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/user) | resource |
| [databricks_user_role.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/user_role) | resource |
| [google_project_iam_custom_role.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.delegate](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_delegate_emails"></a> [delegate\_emails](#input\_delegate\_emails) | List of user or service account emails that may impersonate this service account (roles/iam.serviceAccountTokenCreator). Provide fully-qualified emails; service accounts should be prefixed with 'serviceAccount:'. | `list(string)` | `[]` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID in which the service account and custom IAM role are created. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix applied to the GCP service account ID and custom role ID. Must be lowercase letters, digits, or hyphens, 1-20 characters. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_custom_role_id"></a> [custom\_role\_id](#output\_custom\_role\_id) | Fully-qualified custom IAM role name (projects/<project>/roles/<role\_id>). Pass to downstream IAM bindings if the role is reused. |
| <a name="output_databricks_user_id"></a> [databricks\_user\_id](#output\_databricks\_user\_id) | Databricks account-level user ID of the registered service account. Useful for constructing additional Databricks grants. |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email address of the GCP service account. Used as the Databricks user identity and in IAM bindings. |
| <a name="output_service_account_id"></a> [service\_account\_id](#output\_service\_account\_id) | Fully-qualified GCP service account resource ID (projects/<project>/serviceAccounts/<email>). Use this as service\_account\_id in IAM member resources. |
| <a name="output_service_account_unique_id"></a> [service\_account\_unique\_id](#output\_service\_account\_unique\_id) | GCP-assigned unique ID for the service account. Stable across renames; use for IAM policy conditions. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Variable validations: `project_id`, `databricks_account_id`, `resource_prefix`
- Service account ID computed correctly from `resource_prefix`
- Custom role ID normalises hyphens to underscores
- Delegate IAM members are created for each email in `delegate_emails`
- `databricks_user` is registered with the service account email
- `databricks_user_role` assigns `account_admin`

Run with `terraform test` from the module root.

An apply-command integration test (against a real GCP project + Databricks account) verifies actual service account creation, IAM binding, and Databricks registration. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
