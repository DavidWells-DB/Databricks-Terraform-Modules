# gcp-account-network-cloud-nat

Creates a Cloud Router and Cloud NAT to provide internet egress for private subnets in a GCP VPC network. This is a prerequisite for Databricks clusters in private subnets to reach the Databricks control plane and other internet destinations without public IP addresses.

## What this module abstracts

"Internet egress for a private subnet via managed NAT" — one indivisible function. The Cloud Router and Cloud NAT are tightly coupled: NAT requires a router, and a router created solely for NAT has no independent purpose. Pairing them in one module produces a real abstraction rather than two thin wrappers.

## When to use

- You are provisioning a Databricks workspace in a private subnet (no public IPs on nodes).
- The subnet needs outbound internet access to reach the Databricks control plane, PyPI, Maven, or other external dependencies.
- You want auto-allocated external IPs (Cloud NAT manages the IP pool automatically).

## When NOT to use

- Your VPC already has a Cloud Router/NAT for this region — reference the existing resources at the root composition instead of calling this module.
- You need static external IPs for your NAT — extend this module or manage the `google_compute_address` and NAT IP assignment at the root composition.
- You are deploying a Public IP workspace where nodes have direct internet access — NAT is not needed.

## Minimum platform tier

**Premium.** Private-subnet Databricks workspaces (which this NAT module serves) require Premium tier. A Standard-tier workspace will accept the network configuration but cannot be deployed with nodes that rely on NAT-only egress. See DATABRICKS_RULES.md Rule 2.3.

## Provider configuration

This module uses only the `google` provider. No Databricks provider is required — Cloud Router and Cloud NAT are pure GCP resources with no Databricks-side registration step. Configure the `google` provider at the root composition with the appropriate `project` and `region` (or pass them explicitly; this module passes `project` and `region` to every resource).

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
| [google_compute_router.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_log_config_enable"></a> [log\_config\_enable](#input\_log\_config\_enable) | Whether to enable Cloud NAT logging. When true, NAT translations are logged to Cloud Logging. Useful for network troubleshooting and audit. Defaults to false. | `bool` | `false` | no |
| <a name="input_log_config_filter"></a> [log\_config\_filter](#input\_log\_config\_filter) | Specifies what NAT events to log. Valid values: "ALL" (all NAT events), "ERRORS\_ONLY" (only errors), "TRANSLATIONS\_ONLY" (only successful translations). Only used when log\_config\_enable is true. | `string` | `"ERRORS_ONLY"` | no |
| <a name="input_min_ports_per_vm"></a> [min\_ports\_per\_vm](#input\_min\_ports\_per\_vm) | Minimum number of ports allocated per VM instance for NAT. Higher values reduce port exhaustion risk for workloads with many outbound connections. Defaults to 64. | `number` | `64` | no |
| <a name="input_network_self_link"></a> [network\_self\_link](#input\_network\_self\_link) | Self-link URI of the VPC network to attach the Cloud Router to (format: https://www.googleapis.com/compute/v1/projects/<project>/global/networks/<name>). | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID in which the Cloud Router and Cloud NAT will be created. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the Cloud Router and Cloud NAT (e.g. "us-central1"). Must match the region of the subnets that need egress. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix applied to the Cloud Router name and Cloud NAT name. Must be 1-50 characters; lowercase letters, digits, and hyphens only; must start with a letter. | `string` | n/a | yes |
| <a name="input_subnetwork_self_link"></a> [subnetwork\_self\_link](#input\_subnetwork\_self\_link) | Self-link URI of the subnetwork whose primary and secondary IP ranges should be NAT-translated. The Cloud NAT is configured to cover this subnetwork only (LIST\_OF\_SUBNETWORKS mode). | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_nat_id"></a> [nat\_id](#output\_nat\_id) | Fully-qualified resource ID of the Cloud NAT (projects/<project>/regions/<region>/routers/<router>/nats/<name>). Useful for referencing the NAT configuration in monitoring or policy resources. |
| <a name="output_nat_name"></a> [nat\_name](#output\_nat\_name) | Name of the Cloud NAT resource. |
| <a name="output_router_id"></a> [router\_id](#output\_router\_id) | Fully-qualified resource ID of the Cloud Router (projects/<project>/regions/<region>/routers/<name>). Useful for referencing the router in other GCP resources such as BGP or VPN attachments. |
| <a name="output_router_name"></a> [router\_name](#output\_router\_name) | Name of the Cloud Router. Can be used to reference the router in additional google\_compute\_router\_nat or BGP peer configurations. |
| <a name="output_router_self_link"></a> [router\_self\_link](#output\_router\_self\_link) | Self-link URI of the Cloud Router. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each variable validation block (invalid network self-link, invalid subnetwork self-link, invalid resource_prefix, invalid min_ports_per_vm, invalid log_config_filter).
- Resource attribute assertions (router name suffix, NAT name suffix, NAT mode, min_ports_per_vm passthrough).
- Conditional log_config block (enabled vs. disabled).

Run with `terraform test` from the module root.

An apply-command integration test (against a real GCP project) verifies actual Cloud Router and Cloud NAT creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
