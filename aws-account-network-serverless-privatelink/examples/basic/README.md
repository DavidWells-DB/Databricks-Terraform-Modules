# Basic Example: AWS Serverless PrivateLink to Cloud Service

This example demonstrates how to use the `aws-account-network-serverless-privatelink` module to create the customer-side AWS infrastructure that enables Databricks serverless compute to reach a customer resource (RDS, Redshift, etc.) over PrivateLink.

## What This Example Creates

- Network Load Balancer (internal)
- Target group pointing to the customer resource IP
- VPC endpoint service
- Authorization for Databricks to connect

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Fill in your values:
   - `vpc_id`: Your VPC ID
   - `subnet_ids`: At least one subnet ID (multiple subnets across AZs recommended for HA)
   - `target_ip`: IP address of your RDS/Redshift/etc. endpoint
   - `target_port`: Port your resource listens on (e.g., 5432 for PostgreSQL)
   - `databricks_account_id`: Your Databricks account ID
3. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
4. Use the output `endpoint_service_name` when configuring Databricks serverless PrivateLink.

## Outputs

- `endpoint_service_name`: Provide this to Databricks
- `nlb_dns_name`: DNS name of the NLB
- `nlb_arn`: ARN of the NLB
