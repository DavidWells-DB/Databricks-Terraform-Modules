# aws-account-network-privatelink-endpoints

Creates AWS PrivateLink interface endpoints to the Databricks control plane — workspace REST API and SCC relay (plus optional service-direct) — registers each with the Databricks account API via `databricks_mws_vpc_endpoint`, and creates the associated `databricks_mws_private_access_settings` object that workspaces reference to enable PrivateLink access.

## What this module abstracts

"The PrivateLink connectivity layer between a customer VPC and the Databricks control plane" — one indivisible function per DATABRICKS_RULES.md Rule 1.4. The AWS VPC endpoints and their Databricks-side registrations are paired: splitting them produces thin wrappers; pairing them produces a real abstraction.

## When to use

- You're provisioning a Databricks workspace on AWS and want to restrict control-plane traffic to AWS PrivateLink (no public internet traversal).
- You need Secure Cluster Connectivity (SCC) relay traffic to stay within the VPC.
- You want a single module that creates the AWS-side endpoints AND registers them with the Databricks account API AND creates the Private Access Settings object that the workspace module references.

## When NOT to use

- You already have existing `databricks_mws_vpc_endpoint` registrations — use `data` sources at the root composition instead.
- You're on Azure or GCP — they use different private endpoint mechanisms.
- You want only the AWS-side VPC endpoints without Databricks registration — use `aws-account-network-vpc-endpoints` instead.

## Minimum platform tier

**Enterprise.** The `databricks_mws_private_access_settings` resource and PrivateLink workspace configuration require Enterprise tier. The Databricks Terraform provider does not check tier at plan time; if applied against a workspace below Enterprise tier, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## GovCloud parameterization

The `databricks_gov_shard` input drives the Databricks endpoint service attachment URIs. Both GovCloud shards operate in `us-gov-west-1` but use distinct service IDs.

| Shard | `databricks_gov_shard` | `region` | Workspace service name |
|---|---|---|---|
| Commercial | `null` (default) | any commercial region | From built-in region map |
| GovCloud civilian | `"civilian"` | `"us-gov-west-1"` | `com.amazonaws.vpce.us-gov-west-1.vpce-svc-0f25e28401cbc9418` |
| GovCloud DoD | `"dod"` | `"us-gov-west-1"` | `com.amazonaws.vpce.us-gov-west-1.vpce-svc-08fddf710780b2a54` |

Service direct (`enable_service_direct = true`) is **not available in GovCloud shards**. The variable accepts `false` only when `databricks_gov_shard` is non-null.

Source: https://docs.databricks.com/aws/en/resources/ip-domain-region

## Provider configuration

The module declares `configuration_aliases = [databricks.account]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply:

- A `databricks.account` provider configured against the Databricks account host:
  - Commercial: `https://accounts.cloud.databricks.com`
  - GovCloud civilian: `https://accounts.cloud.databricks.us`
  - GovCloud DoD: `https://accounts-dod.cloud.databricks.mil`
- An `aws` provider configured for the same region as the `region` input.

## Security group

The module creates one security group in the target VPC that is applied to all PrivateLink interface endpoint ENIs. Inbound rules open ports 443 (HTTPS), 2443 (FIPS HTTPS for Compliance Security Profile), and 6666 (SCC relay) from the CIDRs supplied in `security_group_ingress_cidr_blocks`. Outbound allows all traffic. Pass the VPC CIDR and any workspace subnet CIDRs in `security_group_ingress_cidr_blocks`.

## Downstream wiring

- `workspace_vpc_endpoint_id` and `relay_vpc_endpoint_id` feed the `vpc_endpoint_ids` input of `aws-account-network-vpc`.
- `private_access_settings_id` feeds the `private_access_settings_id` input of `aws-account-workspace`.

## Custom service attachment URIs

If your region is not in the module's built-in map, or Databricks publishes updated URIs, provide them via `custom_service_attachment_uris`:

```hcl
custom_service_attachment_uris = {
  workspace = "com.amazonaws.vpce.xx-region-1.vpce-svc-XXXX"
  relay     = "com.amazonaws.vpce.xx-region-1.vpce-svc-YYYY"
}
```

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.50 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_databricks.account"></a> [databricks.account](#provider\_databricks.account) | >= 1.50 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint.relay](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.service_direct](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.workspace](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [databricks_mws_private_access_settings.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_private_access_settings) | resource |
| [databricks_mws_vpc_endpoint.relay](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_vpc_endpoint) | resource |
| [databricks_mws_vpc_endpoint.service_direct](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_vpc_endpoint) | resource |
| [databricks_mws_vpc_endpoint.workspace](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/mws_vpc_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_vpc_endpoint_ids"></a> [allowed\_vpc\_endpoint\_ids](#input\_allowed\_vpc\_endpoint\_ids) | List of databricks\_mws\_vpc\_endpoint IDs allowed to connect when private\_access\_level = "ENDPOINT". Ignored when private\_access\_level = "ACCOUNT". | `list(string)` | `[]` | no |
| <a name="input_custom_service_attachment_uris"></a> [custom\_service\_attachment\_uris](#input\_custom\_service\_attachment\_uris) | Override the module-computed Databricks endpoint service attachment URIs for the workspace, relay, and service-direct endpoints. Use when your region is not in the module's built-in map or when Databricks publishes updated URIs. | <pre>object({<br/>    workspace      = optional(string)<br/>    relay          = optional(string)<br/>    service_direct = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_databricks_gov_shard"></a> [databricks\_gov\_shard](#input\_databricks\_gov\_shard) | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. Drives the endpoint service attachment URIs and account host URL. | `string` | `null` | no |
| <a name="input_enable_service_direct"></a> [enable\_service\_direct](#input\_enable\_service\_direct) | Whether to create a third AWS VPC endpoint for the Databricks service-direct (frontend) PrivateLink service. Not available in GovCloud shards — set to false when databricks\_gov\_shard is non-null. | `bool` | `false` | no |
| <a name="input_private_access_level"></a> [private\_access\_level](#input\_private\_access\_level) | Controls which VPC endpoints may connect to workspaces that use this Private Access Settings object. "ACCOUNT" (default) allows all VPC endpoints registered in the account; "ENDPOINT" restricts to the list in allowed\_vpc\_endpoint\_ids. | `string` | `"ACCOUNT"` | no |
| <a name="input_private_access_settings_name"></a> [private\_access\_settings\_name](#input\_private\_access\_settings\_name) | Display name for the databricks\_mws\_private\_access\_settings object. Must be unique within the Databricks account. | `string` | n/a | yes |
| <a name="input_privatelink_subnet_ids"></a> [privatelink\_subnet\_ids](#input\_privatelink\_subnet\_ids) | List of subnet IDs in which to place the PrivateLink interface endpoint ENIs. Must be in the same VPC as vpc\_id. At least one subnet is required; one per availability zone is recommended. | `list(string)` | n/a | yes |
| <a name="input_public_access_enabled"></a> [public\_access\_enabled](#input\_public\_access\_enabled) | Whether the Databricks workspace can also be accessed over the public internet. true allows both public and PrivateLink access; false restricts access to PrivateLink only. Defaults to false (PrivateLink-only). | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region where the VPC and endpoints reside (e.g. "us-east-1"). Used to look up the Databricks endpoint service attachment URIs and to register endpoints with the Databricks account API. | `string` | n/a | yes |
| <a name="input_relay_vpc_endpoint_name"></a> [relay\_vpc\_endpoint\_name](#input\_relay\_vpc\_endpoint\_name) | Display name for the SCC relay databricks\_mws\_vpc\_endpoint registration. Must be unique within the Databricks account. | `string` | n/a | yes |
| <a name="input_security_group_ingress_cidr_blocks"></a> [security\_group\_ingress\_cidr\_blocks](#input\_security\_group\_ingress\_cidr\_blocks) | CIDR blocks permitted to reach the PrivateLink endpoints. Typically the VPC CIDR and any workspace subnet CIDRs. Ports 443, 2443 (FIPS/CSP), and 6666 (SCC relay) are opened for these blocks. | `list(string)` | n/a | yes |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Name for the AWS security group created to control traffic to the PrivateLink interface endpoints. | `string` | n/a | yes |
| <a name="input_service_direct_vpc_endpoint_name"></a> [service\_direct\_vpc\_endpoint\_name](#input\_service\_direct\_vpc\_endpoint\_name) | Display name for the service-direct databricks\_mws\_vpc\_endpoint registration. Only used when enable\_service\_direct = true. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all AWS resources created by this module (security group and VPC endpoints). | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the AWS VPC in which to create the PrivateLink interface endpoints. | `string` | n/a | yes |
| <a name="input_workspace_vpc_endpoint_name"></a> [workspace\_vpc\_endpoint\_name](#input\_workspace\_vpc\_endpoint\_name) | Display name for the workspace (REST API) databricks\_mws\_vpc\_endpoint registration. Must be unique within the Databricks account. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_private_access_settings_id"></a> [private\_access\_settings\_id](#output\_private\_access\_settings\_id) | Databricks private\_access\_settings\_id. Pass to aws-account-workspace's private\_access\_settings\_id input when creating a workspace with PrivateLink. |
| <a name="output_relay_aws_vpc_endpoint_id"></a> [relay\_aws\_vpc\_endpoint\_id](#output\_relay\_aws\_vpc\_endpoint\_id) | AWS-side ID of the SCC relay interface endpoint (e.g. vpce-xxxxxxxx). |
| <a name="output_relay_service_name"></a> [relay\_service\_name](#output\_relay\_service\_name) | Resolved AWS endpoint service attachment URI for the SCC relay endpoint. |
| <a name="output_relay_vpc_endpoint_id"></a> [relay\_vpc\_endpoint\_id](#output\_relay\_vpc\_endpoint\_id) | Databricks vpc\_endpoint\_id for the SCC relay endpoint. Pass to aws-account-network-vpc's vpc\_endpoint\_ids.dataplane\_relay input. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the AWS security group created for the PrivateLink interface endpoints. |
| <a name="output_service_direct_aws_vpc_endpoint_id"></a> [service\_direct\_aws\_vpc\_endpoint\_id](#output\_service\_direct\_aws\_vpc\_endpoint\_id) | AWS-side ID of the service-direct interface endpoint. null when enable\_service\_direct = false. |
| <a name="output_service_direct_vpc_endpoint_id"></a> [service\_direct\_vpc\_endpoint\_id](#output\_service\_direct\_vpc\_endpoint\_id) | Databricks vpc\_endpoint\_id for the service-direct endpoint. null when enable\_service\_direct = false. |
| <a name="output_workspace_aws_vpc_endpoint_id"></a> [workspace\_aws\_vpc\_endpoint\_id](#output\_workspace\_aws\_vpc\_endpoint\_id) | AWS-side ID of the workspace (REST API) interface endpoint (e.g. vpce-xxxxxxxx). Useful for cross-referencing in AWS Console or CloudFormation. |
| <a name="output_workspace_service_name"></a> [workspace\_service\_name](#output\_workspace\_service\_name) | Resolved AWS endpoint service attachment URI for the workspace endpoint. Useful for verification and debugging — confirms the correct Databricks regional service was targeted. |
| <a name="output_workspace_vpc_endpoint_id"></a> [workspace\_vpc\_endpoint\_id](#output\_workspace\_vpc\_endpoint\_id) | Databricks vpc\_endpoint\_id for the workspace (REST API) endpoint. Pass to aws-account-network-vpc's vpc\_endpoint\_ids.rest\_api input or to allowed\_vpc\_endpoint\_ids when private\_access\_level = "ENDPOINT". |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Each `databricks_gov_shard` value (null, civilian, dod) produces the correct workspace and relay service attachment URIs
- Invalid `databricks_gov_shard`, `vpc_id`, `region`, `privatelink_subnet_ids`, `private_access_level` are rejected by variable validation
- `custom_service_attachment_uris` overrides take precedence over the built-in region map
- `enable_service_direct = false` produces no service-direct resources; `true` produces one
- Computed locals and resource attributes are consistent

Run with `terraform test` from the module root.

An apply-command integration test (against a real AWS + Databricks account) verifies actual VPC endpoint creation and MWS registration. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
