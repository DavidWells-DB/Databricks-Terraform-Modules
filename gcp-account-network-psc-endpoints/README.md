# gcp-account-network-psc-endpoints

Creates GCP Private Service Connect (PSC) forwarding rules to the Databricks workspace and SCC relay endpoints, the private DNS zone that resolves `gcp.databricks.com` to those PSC IPs, and registers both endpoints with the Databricks account API. Also creates the Databricks Private Access Settings object that workspaces reference to enforce private-only connectivity.

## What this module abstracts

"The PSC connectivity Databricks uses for this workspace's network" — one indivisible function. The GCP forwarding rules, DNS records, and their Databricks-side registration are paired per DATABRICKS_RULES.md Rule 1.4: splitting them produces thin wrappers; pairing them produces a real abstraction.

## When to use

- You're provisioning a GCP-hosted Databricks workspace that requires Private Service Connect (PSC) for private network connectivity.
- You want to route workspace and SCC relay traffic through PSC forwarding rules and resolve workspace URLs via a private DNS zone.
- You want a single module that creates the GCP-side resources AND registers them with Databricks, producing a `private_access_settings_id` ready for workspace creation.

## When NOT to use

- You already have PSC endpoints registered in Databricks that you want to reuse — reference them directly in your root composition.
- You're on AWS or Azure — they use VPC endpoints and Private Link, not GCP PSC.
- You need only the GCP-side forwarding rules without Databricks registration — the two are inseparable in this module (Rule 1.4).

## Minimum platform tier

**Enterprise.** PSC with private access enforcement requires Enterprise tier. The Databricks Terraform provider does not check tier at plan time; if applied against a lower-tier account, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.account` provider configured against the Databricks account host (`https://accounts.gcp.databricks.com`).

The `google` provider must be configured for the same GCP project and region as the module inputs.

## Service attachment URIs

The module embeds a static map of Databricks-published PSC service attachment URIs for all 15 supported GCP regions (source: https://docs.databricks.com/gcp/en/resources/ip-domain-region#psc). The correct URI is automatically selected from `var.region`. Use `var.workspace_psc_service_attachment` and `var.relay_psc_service_attachment` to override when Databricks publishes updated URIs for a region.

Supported regions: `asia-northeast1`, `asia-south1`, `asia-southeast1`, `australia-southeast1`, `europe-west1`, `europe-west2`, `europe-west3`, `me-central2`, `northamerica-northeast1`, `southamerica-east1`, `us-central1`, `us-east1`, `us-east4`, `us-west1`, `us-west4`.

## DNS zone

The module creates a single private DNS managed zone for `gcp.databricks.com.` with three record sets:
- `*.gcp.databricks.com.` — wildcard A record resolving to the workspace PSC IP (covers workspace URLs, dp-prefixed names, and regional PSC intermediate hostnames)
- `gcp.databricks.com.` — root A record
- `tunnel.<region>.gcp.databricks.com.` — A record resolving to the SCC relay PSC IP

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
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | 1.117.0 |
| <a name="provider_google"></a> [google](#provider\_google) | 7.35.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_mws_private_access_settings.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_private_access_settings) | resource |
| [databricks_mws_vpc_endpoint.relay](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_vpc_endpoint) | resource |
| [databricks_mws_vpc_endpoint.workspace](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_vpc_endpoint) | resource |
| [google_compute_address.relay](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_address.workspace](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_forwarding_rule.relay](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | resource |
| [google_compute_forwarding_rule.workspace](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | resource |
| [google_dns_managed_zone.databricks](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone) | resource |
| [google_dns_record_set.relay](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_dns_record_set.workspace_root](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_dns_record_set.workspace_wildcard](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_vpc_endpoint_ids"></a> [allowed\_vpc\_endpoint\_ids](#input\_allowed\_vpc\_endpoint\_ids) | List of Databricks VPC endpoint IDs allowed to connect when private\_access\_level is ENDPOINT. Ignored when private\_access\_level is ACCOUNT. | `list(string)` | `[]` | no |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Used to register PSC endpoints via the account API. | `string` | n/a | yes |
| <a name="input_network_self_link"></a> [network\_self\_link](#input\_network\_self\_link) | Self-link of the GCP VPC network in which the PSC forwarding rules are created. Example: projects/my-project/global/networks/my-vpc. | `string` | n/a | yes |
| <a name="input_private_access_level"></a> [private\_access\_level](#input\_private\_access\_level) | The level of access allowed for the private access settings. ACCOUNT allows all VPC endpoints in the account; ENDPOINT restricts to var.allowed\_vpc\_endpoint\_ids. | `string` | `"ACCOUNT"` | no |
| <a name="input_private_access_settings_name"></a> [private\_access\_settings\_name](#input\_private\_access\_settings\_name) | Descriptive name for the Databricks Private Access Settings object. Defaults to <resource\_prefix>-pas when null. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google Cloud project ID in which the PSC compute addresses and forwarding rules are created. | `string` | n/a | yes |
| <a name="input_psc_subnet_self_link"></a> [psc\_subnet\_self\_link](#input\_psc\_subnet\_self\_link) | Self-link of the subnet used for PSC endpoint IP address allocation. The subnet must be in the same region as var.region. Example: projects/my-project/regions/us-central1/subnetworks/my-psc-subnet. | `string` | n/a | yes |
| <a name="input_public_access_enabled"></a> [public\_access\_enabled](#input\_public\_access\_enabled) | Whether public internet access to Databricks workspaces associated with this Private Access Settings object is allowed. Set to false to enforce private-only access. | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | GCP region for PSC endpoints. Must match the region of the Databricks workspace VPC. Supported regions: asia-northeast1, asia-south1, asia-southeast1, australia-southeast1, europe-west1, europe-west2, europe-west3, me-central2, northamerica-northeast1, southamerica-east1, us-central1, us-east1, us-east4, us-west1, us-west4. | `string` | n/a | yes |
| <a name="input_relay_psc_service_attachment"></a> [relay\_psc\_service\_attachment](#input\_relay\_psc\_service\_attachment) | Optional override for the Databricks SCC relay PSC service attachment URI. When null the module computes the correct URI from var.region using the documented Databricks PSC attachment map. Override only if Databricks has published an updated URI for your region. | `string` | `null` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix applied to all GCP and Databricks resource names created by this module. Keep short (under 20 characters) to stay within GCP's 63-character name limits. | `string` | n/a | yes |
| <a name="input_workspace_psc_service_attachment"></a> [workspace\_psc\_service\_attachment](#input\_workspace\_psc\_service\_attachment) | Optional override for the Databricks workspace PSC service attachment URI. When null the module computes the correct URI from var.region using the documented Databricks PSC attachment map. Override only if Databricks has published an updated URI for your region. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_dns_zone_name"></a> [dns\_zone\_name](#output\_dns\_zone\_name) | GCP name of the private DNS managed zone created for gcp.databricks.com. |
| <a name="output_private_access_settings_id"></a> [private\_access\_settings\_id](#output\_private\_access\_settings\_id) | Databricks Private Access Settings ID. Pass to workspace creation modules as private\_access\_settings\_id. |
| <a name="output_relay_psc_endpoint_id"></a> [relay\_psc\_endpoint\_id](#output\_relay\_psc\_endpoint\_id) | Databricks VPC endpoint ID for the SCC relay PSC forwarding rule. |
| <a name="output_relay_psc_forwarding_rule_id"></a> [relay\_psc\_forwarding\_rule\_id](#output\_relay\_psc\_forwarding\_rule\_id) | GCP self-link of the SCC relay PSC forwarding rule resource. |
| <a name="output_relay_psc_ip"></a> [relay\_psc\_ip](#output\_relay\_psc\_ip) | Internal IP address allocated for the SCC relay PSC forwarding rule. |
| <a name="output_relay_psc_service_attachment"></a> [relay\_psc\_service\_attachment](#output\_relay\_psc\_service\_attachment) | Effective SCC relay PSC service attachment URI used for the forwarding rule. Reflects the computed-or-overridden value. Useful for audit and debugging. |
| <a name="output_workspace_psc_endpoint_id"></a> [workspace\_psc\_endpoint\_id](#output\_workspace\_psc\_endpoint\_id) | Databricks VPC endpoint ID for the workspace PSC forwarding rule. Pass to workspace creation modules as part of the private access configuration. |
| <a name="output_workspace_psc_forwarding_rule_id"></a> [workspace\_psc\_forwarding\_rule\_id](#output\_workspace\_psc\_forwarding\_rule\_id) | GCP self-link of the workspace PSC forwarding rule resource. |
| <a name="output_workspace_psc_ip"></a> [workspace\_psc\_ip](#output\_workspace\_psc\_ip) | Internal IP address allocated for the workspace PSC forwarding rule. Useful for verifying DNS resolution. |
| <a name="output_workspace_psc_service_attachment"></a> [workspace\_psc\_service\_attachment](#output\_workspace\_psc\_service\_attachment) | Effective workspace PSC service attachment URI used for the forwarding rule. Reflects the computed-or-overridden value. Useful for audit and debugging. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each supported region resolves to the correct workspace and relay PSC service attachment URI from the locals map.
- An unsupported region is rejected by variable validation.
- Invalid `resource_prefix` patterns are rejected by variable validation.
- Invalid `private_access_level` is rejected by variable validation.
- Service attachment override inputs propagate to the effective locals.
- Resource attribute checks: forwarding rule names, DNS zone name, PAS region.

Run with `terraform test` from the module root.

An apply-command integration test (against a real GCP project + Databricks account) verifies actual PSC endpoint creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
