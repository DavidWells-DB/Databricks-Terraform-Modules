# Example: basic

Minimum invocation of the `aws-account-network-privatelink-endpoints` module against a commercial AWS account (us-east-1).

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values.
2. Configure AWS credentials for the target account (via environment variables, profile, or IAM role).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring both `aws` and `databricks.account` providers at the root.
- Passing the `databricks.account` provider alias to the module.
- Commercial (non-GovCloud) deployment with `databricks_gov_shard = null`.
- `public_access_enabled = true` to allow both public and PrivateLink access (useful during migration).
- `private_access_level = "ACCOUNT"` (default) — all account-registered VPC endpoints may connect.
- Service-direct endpoint disabled (default).

## Outputs

- `workspace_vpc_endpoint_id` — Pass to `aws-account-network-vpc` as `vpc_endpoint_ids.rest_api`.
- `relay_vpc_endpoint_id` — Pass to `aws-account-network-vpc` as `vpc_endpoint_ids.dataplane_relay`.
- `private_access_settings_id` — Pass to `aws-account-workspace` as `private_access_settings_id`.
- `security_group_id` — The security group attached to all PrivateLink endpoint ENIs.
- `workspace_service_name` — The resolved AWS endpoint service URI (for verification).
