# Example: basic

Minimum invocation of the `aws-account-network-vpc-peering` module demonstrating same-account, same-region VPC peering between a Databricks data-plane VPC and a hub or shared-services VPC.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your VPC IDs, CIDRs, route table IDs, and AWS account ID.
2. Configure AWS credentials for the target account (via environment variables, profile, or IAM role).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `aws` provider at the root composition.
- Passing all required inputs to the module for a same-account, same-region peering.
- Routing both directions (data-plane VPC → shared-services VPC, and vice versa) via the `requester_route_table_ids` and `accepter_route_table_ids` inputs.

## Outputs

- `peering_connection_id` — ID of the established VPC peering connection. Reference this in security group rules or downstream modules that need to allow traffic over the peering link.
- `peering_connection_status` — Status of the connection after acceptance (should be `active`).
