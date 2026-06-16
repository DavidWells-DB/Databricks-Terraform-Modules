# gcp-account-network-shared-vpc

Configures a GCP project as a Shared VPC host and attaches one or more service projects, with optional subnet-level IAM grants for service-project service accounts.

## What this module abstracts

"The Shared VPC configuration that Databricks GCP workspaces use" — the indivisible pairing of the host project enablement (`google_compute_shared_vpc_host_project`), the service project attachments (`google_compute_shared_vpc_service_project`), and optional subnet IAM grants (`google_compute_subnetwork_iam_member`). These three concerns always move together when configuring a Shared VPC for Databricks.

## When to use

- You are preparing a GCP Shared VPC topology for Databricks workspace deployment where Databricks worker nodes are launched in a service project but network resources live in a host project.
- You want a single module that establishes the host/service relationship and optionally grants fine-grained subnet access to service-project service accounts.

## When NOT to use

- You already have an existing Shared VPC host project configured by another team — manage the VPC topology outside Terraform or via a `data` source and pass the resulting project IDs to your workspace module directly.
- You are using a standalone (non-Shared VPC) GCP network for Databricks — use a different network module.
- You need to create the VPC network itself (subnets, firewall rules) — this module manages only the Shared VPC host/service binding and subnet IAM, not the underlying network resources.

## Minimum platform tier

**Premium.** Databricks GCP workspaces require a Premium-tier Databricks account. The Terraform provider does not check tier at plan time; if applied against a Standard-tier account, workspace creation will fail at apply time. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

This module uses only the `google` (hashicorp/google) provider. No Databricks provider is required — this module manages pure GCP infrastructure. Configure the `google` provider in the root composition with credentials that have the following IAM permissions on the host project:

- `compute.xpnAdmin` (Shared VPC Admin) on the host project — required for `google_compute_shared_vpc_host_project` and `google_compute_shared_vpc_service_project`
- `compute.subnetworks.setIamPolicy` on the host project (or specific subnets) — required for `google_compute_subnetwork_iam_member` when `subnet_iam_grants` is non-empty

The service account or user running Terraform must also have `compute.xpnAdmin` on the organization or folder containing both the host and service projects, depending on your GCP IAM topology.

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
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_shared_vpc_host_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_shared_vpc_host_project) | resource |
| [google_compute_shared_vpc_service_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_shared_vpc_service_project) | resource |
| [google_compute_subnetwork_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_host_project_id"></a> [host\_project\_id](#input\_host\_project\_id) | GCP project ID of the Shared VPC host project. This project will be configured as the Shared VPC host. | `string` | n/a | yes |
| <a name="input_service_project_ids"></a> [service\_project\_ids](#input\_service\_project\_ids) | List of GCP project IDs to attach as Shared VPC service projects. At least one service project is required. | `list(string)` | n/a | yes |
| <a name="input_subnet_iam_grants"></a> [subnet\_iam\_grants](#input\_subnet\_iam\_grants) | Optional list of IAM bindings to add on specific subnetworks in the host project. Each entry grants a single member a single role on a single subnetwork. Useful for granting service-project service accounts access to Shared VPC subnets (e.g., roles/compute.networkUser). Leave empty to skip subnet-level IAM grants. | <pre>list(object({<br/>    subnetwork = string<br/>    region     = string<br/>    member     = string<br/>    role       = string<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_host_project_id"></a> [host\_project\_id](#output\_host\_project\_id) | GCP project ID of the Shared VPC host project. Pass to workspace or network modules that require the host project reference. |
| <a name="output_service_project_attachment_ids"></a> [service\_project\_attachment\_ids](#output\_service\_project\_attachment\_ids) | Map of service project ID to the Terraform resource ID of its Shared VPC attachment (format: host\_project/service\_project). Useful for referencing or importing attachments. |
| <a name="output_service_project_ids"></a> [service\_project\_ids](#output\_service\_project\_ids) | Set of GCP project IDs attached as Shared VPC service projects. |
| <a name="output_subnet_iam_grant_ids"></a> [subnet\_iam\_grant\_ids](#output\_subnet\_iam\_grant\_ids) | Map of subnet IAM grant key (subnetwork/region/member/role) to the Terraform resource ID of the google\_compute\_subnetwork\_iam\_member resource. Empty when no subnet\_iam\_grants are configured. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Host project and service project resources are planned with expected attributes.
- Multiple service project attachments are created correctly (one per entry in `service_project_ids`).
- Subnet IAM grants are created when `subnet_iam_grants` is non-empty.
- Invalid `host_project_id` and `service_project_ids` entries are rejected by variable validation.
- Empty `service_project_ids` is rejected by variable validation.

Run with `terraform test` from the module root.

An apply-command integration test (against a real GCP project) verifies actual Shared VPC host enablement and service project attachment. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
