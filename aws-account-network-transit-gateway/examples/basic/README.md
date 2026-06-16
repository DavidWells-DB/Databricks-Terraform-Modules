# Example: basic

Minimum invocation of the `aws-account-network-transit-gateway` module against a commercial AWS account. Creates a Transit Gateway and attaches two VPCs — a Databricks workspace VPC and a shared-services VPC — using a single shared route table.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in real VPC and subnet IDs from your AWS account.
2. Configure AWS credentials for the target account (via environment variables, profile, or IAM role).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `aws` provider at the root composition.
- Passing a `vpc_attachments` map with two entries (workspace VPC and shared-services VPC).
- Using the module's opinionated defaults: DNS support enabled, VPN ECMP enabled, default route table association and propagation disabled (hub-and-spoke pattern).

## Outputs

- `transit_gateway_id` — Pass to `aws_route` resources in VPC route tables to forward traffic through the TGW.
- `attachment_ids` — Map of attachment name to attachment ID (useful for RAM sharing or debugging).
- `route_table_id` — Pass to `aws_ec2_transit_gateway_route` resources at the root composition to add static routes.
