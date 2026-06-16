# gcp-account-network-vpc

Creates the GCP VPC, subnetwork (with secondary IP ranges for GKE pods and services), Databricks-required firewall rules, and registers the network configuration with Databricks via `databricks_mws_networks`.

## What this module abstracts

"The network Databricks uses to manage this workspace's compute" — one indivisible function. The GCP VPC, subnetwork, firewall rules, and Databricks-side network registration are paired per DATABRICKS_RULES.md Rule 1.4: splitting them produces thin wrappers; pairing them produces a real abstraction.

## When to use

- You are provisioning a new GCP-hosted Databricks workspace with a customer-managed VPC (CMVPC).
- You want a single module that creates the GCP network resources AND registers them as a Databricks network configuration.
- You need secondary IP ranges pre-configured for GKE pod and service networking.

## When NOT to use

- You already have a `databricks_mws_networks` object you want to reuse — use a `data` source at the root composition instead.
- You are on AWS or Azure — they use different network registration mechanisms.
- Your VPC is managed by a separate networking team — at the root composition, look up the existing subnetwork and reference its details in a `databricks_mws_networks` resource directly.
- You need Shared VPC (XPN) host/service project wiring — use `gcp-account-network-shared-vpc` instead.

## Minimum platform tier

**Premium.** The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier account, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply:

- A `databricks.account` provider configured against the GCP Databricks account host (`https://accounts.gcp.databricks.com`).
- A `google` provider configured for the target GCP project and region.

## PSC wiring (optional)

The optional `vpc_endpoint_ids` input accepts PSC endpoint IDs from `gcp-account-network-psc-endpoints`. When provided, they are wired into the `databricks_mws_networks` registration via the `vpc_endpoints` block. PSC endpoints can be added after initial workspace creation by re-running with this input set.

## Secondary IP ranges

The subnetwork is created with two secondary IP ranges:

| Range | Purpose | Default name pattern |
|---|---|---|
| `pod_secondary_range_cidr` | GKE pod networking | `<resource_prefix>-pods` |
| `service_secondary_range_cidr` | GKE service networking | `<resource_prefix>-services` |

These names are exposed as outputs (`pod_secondary_range_name`, `service_secondary_range_name`) for use with downstream modules or GKE node pool configurations.

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
| [databricks_mws_networks.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_networks) | resource |
| [google_compute_firewall.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_network.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_subnetwork.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Used to register the network configuration with the Databricks account API. | `string` | n/a | yes |
| <a name="input_network_cidr"></a> [network\_cidr](#input\_network\_cidr) | Primary CIDR block for the VPC subnetwork. Databricks requires a subnet between /9 and /29 (e.g. "10.0.0.0/16"). | `string` | n/a | yes |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Name for the databricks\_mws\_networks registration. Should be descriptive and unique within the Databricks account. | `string` | n/a | yes |
| <a name="input_pod_secondary_range_cidr"></a> [pod\_secondary\_range\_cidr](#input\_pod\_secondary\_range\_cidr) | CIDR for the secondary IP range used by GKE pods. Required by Databricks GCP workspaces for cluster pod networking (e.g. "10.1.0.0/16"). | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID in which the VPC, subnetwork, and firewall rules are created. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the subnetwork and Databricks workspace data plane (e.g. "us-central1"). Must match the region used by the Databricks workspace. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix applied to the VPC, subnetwork, and firewall resource names. Must be 1-20 characters, lowercase letters, digits, or hyphens, starting with a letter. | `string` | n/a | yes |
| <a name="input_service_secondary_range_cidr"></a> [service\_secondary\_range\_cidr](#input\_service\_secondary\_range\_cidr) | CIDR for the secondary IP range used by GKE services. Required by Databricks GCP workspaces for cluster service networking (e.g. "10.2.0.0/20"). | `string` | n/a | yes |
| <a name="input_vpc_endpoint_ids"></a> [vpc\_endpoint\_ids](#input\_vpc\_endpoint\_ids) | Optional PSC (Private Service Connect) endpoint IDs from gcp-account-network-psc-endpoints. When provided, wired into the databricks\_mws\_networks registration to enable PSC connectivity. Set to null to skip PSC wiring. | <pre>object({<br/>    dataplane_relay = optional(list(string))<br/>    rest_api        = optional(list(string))<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_databricks_network_id"></a> [databricks\_network\_id](#output\_databricks\_network\_id) | Databricks network configuration ID from databricks\_mws\_networks. Pass to workspace creation modules as their network\_id input. |
| <a name="output_network_cidr"></a> [network\_cidr](#output\_network\_cidr) | Primary CIDR block of the subnetwork. Useful for constructing downstream firewall rules that reference the workspace subnet range. |
| <a name="output_network_name"></a> [network\_name](#output\_network\_name) | Name of the created VPC network. Useful for firewall rules or Shared VPC host configurations. |
| <a name="output_network_self_link"></a> [network\_self\_link](#output\_network\_self\_link) | Self-link of the created VPC. Pass to downstream modules (e.g., gcp-account-network-cloud-nat, gcp-account-network-psc-endpoints) as their network\_self\_link input. |
| <a name="output_pod_secondary_range_name"></a> [pod\_secondary\_range\_name](#output\_pod\_secondary\_range\_name) | Name of the secondary IP range reserved for GKE pods. Required when configuring GKE node pools or PSC subnets that reference this range. |
| <a name="output_service_secondary_range_name"></a> [service\_secondary\_range\_name](#output\_service\_secondary\_range\_name) | Name of the secondary IP range reserved for GKE services. Required when configuring GKE node pools or PSC subnets that reference this range. |
| <a name="output_subnetwork_name"></a> [subnetwork\_name](#output\_subnetwork\_name) | Name of the created subnetwork. |
| <a name="output_subnetwork_self_link"></a> [subnetwork\_self\_link](#output\_subnetwork\_self\_link) | Self-link of the created subnetwork. Pass to downstream modules (e.g., gcp-account-network-psc-endpoints) as their subnetwork\_self\_link input. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each variable validation (project_id format, region format, resource_prefix constraints, CIDR validity, network_cidr /9-/29 bounds, network_name constraints, databricks_account_id UUID format)
- Resource attribute checks (VPC name, subnetwork name, firewall rule name, secondary range names)
- PSC conditional logic (vpc_endpoints block present only when vpc_endpoint_ids is provided)

Run with `terraform test` from the module root.

An apply-command integration test (against a real GCP project + Databricks account) verifies actual VPC creation and network registration. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
