# gcp-account-vpc-service-controls

Creates a VPC Service Controls perimeter for GCP projects, restricting data egress at the organizational level.

## What this module abstracts

VPC Service Controls perimeter creation for organizational data security compliance — a single perimeter configuration that governs which GCP services are accessible and under what conditions for protected projects.

## When to use

- You're implementing VPC Service Controls to restrict data egress from GCP projects.
- You need to create a service perimeter that wraps one or more GCP projects.
- You want to control access to GCP services (like Cloud Storage, BigQuery) at the organizational boundary.

## When NOT to use

- You already have a VPC Service Controls perimeter you want to reuse — use a `data` source at the root composition instead.
- You need to create the Access Context Manager access policy itself — this module requires an existing policy as input.
- Your organization doesn't require VPC Service Controls (this is a Premium-tier security control).

## Minimum platform tier

**Premium.** VPC Service Controls is a GCP security premium feature. The Google provider does not check tier at plan time; if applied against a project without VPC Service Controls enabled, the API will reject and apply will fail.

## Access policy requirement

This module requires an existing Access Context Manager access policy at the organization level. The `access_policy_id` input can be in either format:
- Full resource name: `accessPolicies/<policy_id>`
- Just the policy ID: `<policy_id>`

The module will normalize to the full resource name format.

## Project number normalization

The `protected_project_numbers` input accepts project numbers in either format:
- Full resource name: `projects/<project_number>`
- Just the project number: `<project_number>`

The module will normalize all entries to the full resource name format.

## Provider configuration

The module uses the default `google` provider. The caller must ensure the provider is configured with credentials that have permission to manage Access Context Manager resources at the organization level.

Typical required roles:
- `roles/accesscontextmanager.policyAdmin` — to create/manage service perimeters

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
| <a name="provider_google"></a> [google](#provider\_google) | 7.35.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_access_context_manager_service_perimeter.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_service_perimeter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_levels"></a> [access\_levels](#input\_access\_levels) | List of access level resource names to allow ingress. Format: accessPolicies/<policy\_id>/accessLevels/<level\_name>. | `list(string)` | `[]` | no |
| <a name="input_access_policy_id"></a> [access\_policy\_id](#input\_access\_policy\_id) | Existing Access Context Manager access policy ID (organization-level). Format: accessPolicies/<policy\_id> or <policy\_id>. | `string` | n/a | yes |
| <a name="input_egress_policies"></a> [egress\_policies](#input\_egress\_policies) | Egress policy rules for the perimeter. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_service_perimeter#egress_policies for structure. | <pre>list(object({<br/>    egress_from = optional(object({<br/>      identity_type = optional(string)<br/>      identities    = optional(list(string), [])<br/>    }))<br/>    egress_to = optional(object({<br/>      resources = optional(list(string), [])<br/>      operations = optional(list(object({<br/>        service_name = optional(string)<br/>        method_selectors = optional(list(object({<br/>          method     = optional(string)<br/>          permission = optional(string)<br/>        })), [])<br/>      })), [])<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_ingress_policies"></a> [ingress\_policies](#input\_ingress\_policies) | Ingress policy rules for the perimeter. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_service_perimeter#ingress_policies for structure. | <pre>list(object({<br/>    ingress_from = optional(object({<br/>      sources = optional(list(object({<br/>        access_level = optional(string)<br/>        resource     = optional(string)<br/>      })), [])<br/>      identity_type = optional(string)<br/>      identities    = optional(list(string), [])<br/>    }))<br/>    ingress_to = optional(object({<br/>      resources = optional(list(string), [])<br/>      operations = optional(list(object({<br/>        service_name = optional(string)<br/>        method_selectors = optional(list(object({<br/>          method     = optional(string)<br/>          permission = optional(string)<br/>        })), [])<br/>      })), [])<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_perimeter_name"></a> [perimeter\_name](#input\_perimeter\_name) | Name of the service perimeter. Must be alphanumeric with underscores, max 50 chars. | `string` | n/a | yes |
| <a name="input_perimeter_title"></a> [perimeter\_title](#input\_perimeter\_title) | Human-readable title for the service perimeter. | `string` | n/a | yes |
| <a name="input_protected_project_numbers"></a> [protected\_project\_numbers](#input\_protected\_project\_numbers) | List of GCP project numbers to include in the perimeter. Format: "projects/<project\_number>" or "<project\_number>". | `list(string)` | n/a | yes |
| <a name="input_restricted_services"></a> [restricted\_services](#input\_restricted\_services) | List of GCP services restricted by the perimeter (e.g., "storage.googleapis.com", "bigquery.googleapis.com"). | `list(string)` | <pre>[<br/>  "storage.googleapis.com",<br/>  "bigquery.googleapis.com"<br/>]</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_perimeter_id"></a> [perimeter\_id](#output\_perimeter\_id) | Full resource name of the VPC Service Controls perimeter. |
| <a name="output_perimeter_name"></a> [perimeter\_name](#output\_perimeter\_name) | Name of the service perimeter. |
| <a name="output_protected_projects"></a> [protected\_projects](#output\_protected\_projects) | List of GCP project numbers protected by the perimeter. |
| <a name="output_restricted_services"></a> [restricted\_services](#output\_restricted\_services) | List of GCP services restricted by the perimeter. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Variable validation for `perimeter_name`, `perimeter_title`, and `protected_project_numbers`
- Resource attributes match input variables
- Normalization of access policy ID and project numbers

Run with `terraform test` from the module root.

An apply-command integration test (against a real GCP organization with VPC Service Controls enabled) verifies actual perimeter creation. It is credential-gated and will be added when the test environment is configured.
