# gcp-account-network-cloud-ngfw

Creates a Cloud NGFW (Next Generation Firewall) inspection stack for a GCP VPC network: a threat-prevention security profile, a security profile group referencing it, a zonal firewall endpoint, and the firewall endpoint association that links them to the VPC.

## What this module abstracts

"The Cloud NGFW egress inspection configuration for a VPC network" — one indivisible function. The four Cloud NGFW resources are tightly coupled:

1. **Security profile** — declares threat-prevention behavior (severity and threat-ID overrides).
2. **Security profile group** — groups the profile; this is what network firewall policy rules reference via `security_profile_group`.
3. **Firewall endpoint** — zonal compute capacity that performs Layer 7 inspection; billed to a project.
4. **Firewall endpoint association** — binds the endpoint to the VPC network in the same zone so matched traffic is steered for inspection.

Splitting these into separate modules produces thin wrappers; keeping them together produces a real abstraction per DATABRICKS_RULES.md Rule 1.4.

## When to use

- You are deploying a Databricks workspace on GCP and want Cloud NGFW to inspect egress traffic from the compute VPC.
- You need to configure threat-prevention with custom severity or threat-ID overrides.

## When NOT to use

- You already have a firewall endpoint and only need to manage the association — use the `google_network_security_firewall_endpoint_association` resource directly.
- You need URL filtering (`URL_FILTERING` profile type) — extend this module in a future MINOR by adding a `url_filtering_profile` variable.
- You are on AWS or Azure — they use different firewall inspection mechanisms.

## Minimum platform tier

**Premium.** Cloud NGFW is a GCP-side resource; Databricks platform tier does not gate its creation. However, this module is typically deployed as part of a Premium-tier Databricks workspace network configuration. Deploying this module requires an active GCP organization with Cloud Firewall Plus APIs enabled.

## Provider configuration notes

This module uses only the `google` (GA) provider. No `google-beta` provider is required — `google_network_security_security_profile`, `google_network_security_security_profile_group`, `google_network_security_firewall_endpoint`, and `google_network_security_firewall_endpoint_association` are all GA resources as of `google` 6.x.

The caller must configure the `google` provider with credentials that have the following IAM roles:
- `roles/networksecurity.admin` (or equivalent) at the organization level for security profiles, profile groups, and firewall endpoints.
- `roles/compute.networkAdmin` at the project level for the firewall endpoint association.

## Long-running resources

The `google_network_security_firewall_endpoint` resource can take up to 60 minutes to reach ACTIVE state. The Terraform provider waits for this automatically. Plan for a long `terraform apply` on first deployment.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_network_security_firewall_endpoint.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_security_firewall_endpoint) | resource |
| [google_network_security_firewall_endpoint_association.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_security_firewall_endpoint_association) | resource |
| [google_network_security_security_profile.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_security_security_profile) | resource |
| [google_network_security_security_profile_group.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_security_security_profile_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels applied to all resources created by this module. | `map(string)` | `{}` | no |
| <a name="input_network_self_link"></a> [network\_self\_link](#input\_network\_self\_link) | Self-link of the VPC network to associate with the firewall endpoint. Format: "https://www.googleapis.com/compute/v1/projects/{project}/global/networks/{network}". | `string` | n/a | yes |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | GCP organization ID. Used as the parent for the security profile, security profile group, and firewall endpoint. Format: numeric organization ID (e.g. "123456789"). | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID. Used as the billing project for firewall endpoint charges and as the parent for the firewall endpoint association. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix applied to all resource names created by this module (security profile, security profile group, firewall endpoint, association). Must be 1-30 characters, lowercase alphanumeric and hyphens. | `string` | n/a | yes |
| <a name="input_severity_overrides"></a> [severity\_overrides](#input\_severity\_overrides) | List of threat-prevention severity overrides for the security profile. Each entry overrides the default action for a severity level. action must be one of ALERT, ALLOW, DEFAULT\_ACTION, DENY. severity must be one of CRITICAL, HIGH, INFORMATIONAL, LOW, MEDIUM. | <pre>list(object({<br/>    action   = string<br/>    severity = string<br/>  }))</pre> | `[]` | no |
| <a name="input_threat_overrides"></a> [threat\_overrides](#input\_threat\_overrides) | List of threat-prevention threat-ID overrides for the security profile. action must be one of ALERT, ALLOW, DEFAULT\_ACTION, DENY. | <pre>list(object({<br/>    action    = string<br/>    threat_id = string<br/>  }))</pre> | `[]` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | GCP zone for the firewall endpoint and firewall endpoint association. Cloud NGFW firewall endpoints are zonal resources. Example: "us-central1-a". | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_firewall_endpoint_association_id"></a> [firewall\_endpoint\_association\_id](#output\_firewall\_endpoint\_association\_id) | Fully-qualified resource ID of the firewall endpoint association. Format: projects/{project}/locations/{zone}/firewallEndpointAssociations/{name}. |
| <a name="output_firewall_endpoint_association_state"></a> [firewall\_endpoint\_association\_state](#output\_firewall\_endpoint\_association\_state) | Current state of the firewall endpoint association. Traffic steering is only active when this is ACTIVE. |
| <a name="output_firewall_endpoint_id"></a> [firewall\_endpoint\_id](#output\_firewall\_endpoint\_id) | Fully-qualified resource ID of the Cloud NGFW firewall endpoint. Format: organizations/{org}/locations/{zone}/firewallEndpoints/{name}. |
| <a name="output_firewall_endpoint_self_link"></a> [firewall\_endpoint\_self\_link](#output\_firewall\_endpoint\_self\_link) | Server-defined URL of the Cloud NGFW firewall endpoint. Useful for cross-referencing in firewall policy rules. |
| <a name="output_firewall_endpoint_state"></a> [firewall\_endpoint\_state](#output\_firewall\_endpoint\_state) | Current state of the Cloud NGFW firewall endpoint (e.g. ACTIVE). Used to verify the endpoint is ready before associating firewall policy rules. |
| <a name="output_security_profile_group_id"></a> [security\_profile\_group\_id](#output\_security\_profile\_group\_id) | Fully-qualified resource ID of the Cloud NGFW security profile group. Reference this in network firewall policy rules via the security\_profile\_group field. |
| <a name="output_security_profile_group_name"></a> [security\_profile\_group\_name](#output\_security\_profile\_group\_name) | Display name of the Cloud NGFW security profile group resource. |
| <a name="output_security_profile_id"></a> [security\_profile\_id](#output\_security\_profile\_id) | Fully-qualified resource ID of the Cloud NGFW security profile. Format: organizations/{org}/locations/global/securityProfiles/{name}. |
| <a name="output_security_profile_name"></a> [security\_profile\_name](#output\_security\_profile\_name) | Display name of the Cloud NGFW security profile resource. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each variable validation (invalid org ID, invalid project ID, invalid zone, invalid network self-link, invalid resource prefix, invalid severity/threat override actions).
- Resource attribute assertions: names are prefixed correctly, parents match org/project inputs.
- Locals: `org_parent` and `project_parent` are constructed correctly.

Run with `terraform test` from the module root.

An apply-command integration test (against a real GCP organization) verifies actual resource creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
