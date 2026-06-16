# Example: basic

Minimum invocation of the `aws-account-network-vpc` module against a commercial AWS account.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks account ID and service principal credentials.
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
- A minimal two-AZ VPC with two private subnets and two public subnets.
- Commercial (non-GovCloud) deployment with `databricks_gov_shard = null`.
- No PrivateLink endpoints (`vpc_endpoint_ids` is omitted).

## Outputs

- `vpc_id` — Pass to downstream modules such as `aws-account-network-egress-internet` or `aws-account-network-vpc-endpoints`.
- `private_subnet_ids` — Pass to `aws-account-network-vpc-endpoints` as its `private_subnet_ids` input.
- `security_group_id` — Pass to `aws-account-network-vpc-endpoints` as its `security_group_id` input.
- `databricks_network_id` — Pass to workspace creation modules as their `network_id` input.
- `private_route_table_ids` — Pass to `aws-account-network-egress-internet` and `aws-account-network-vpc-endpoints` (S3 gateway).
