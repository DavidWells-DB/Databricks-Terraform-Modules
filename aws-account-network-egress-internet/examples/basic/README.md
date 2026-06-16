# Example: basic

Minimum invocation of the `aws-account-network-egress-internet` module against an existing AWS VPC.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your VPC ID, public subnet IDs, and private route table IDs.
2. Configure AWS credentials for the target account (via environment variables, profile, or IAM role).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `aws` provider at the root.
- Passing an existing VPC, public subnets, and private route tables to the module.
- Single NAT Gateway (non-HA) deployment.

## Outputs

- `internet_gateway_id` — The Internet Gateway attached to the VPC.
- `nat_gateway_id` — The NAT Gateway placed in the first public subnet.
- `nat_public_ip` — The public Elastic IP of the NAT Gateway. Use this for firewall egress allowlisting.
