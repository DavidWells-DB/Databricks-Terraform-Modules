# Example: basic

Minimum invocation of the `aws-account-network-firewall` module against a commercial AWS account.

This example deploys the firewall in "pass-through" mode — all stateless traffic is forwarded to the stateful engine, and no rule groups are associated. Add rule group ARNs to `stateful_rule_group_arns` and `stateless_rule_group_arns` for real traffic filtering.

## Pre-requisites

This example assumes you have already created:
- A VPC (e.g., via `aws-account-network-vpc`)
- Dedicated firewall subnets within that VPC (one per AZ you want HA coverage)
- Private route tables for the Databricks compute subnets

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

- Deploying the Network Firewall with no inline rule groups (pass-through mode).
- Wiring route tables to the firewall endpoints automatically.
- Using the default stateless action (`aws:forward_to_sfe`) to send all traffic to the stateful engine.

## Outputs

- `firewall_id` — Resource ID of the Network Firewall.
- `firewall_arn` — ARN for use in IAM policies and CloudWatch logging configuration.
- `firewall_policy_arn` — ARN for attaching additional rule groups after deployment.
