# Example: basic

Minimum invocation of the `aws-account-network-vpc-endpoints` module against a commercial AWS account with an existing VPC.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your VPC and subnet IDs.
2. Configure AWS credentials for the target account (via environment variables, profile, or IAM role).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `aws` provider at the root composition.
- Passing an existing VPC ID, private subnet IDs, security group IDs, and route table IDs to the module.
- Using the module defaults for a commercial (non-GovCloud) deployment.

## Outputs

- `s3_endpoint_id` — ID of the S3 gateway endpoint (useful for downstream bucket policy scope conditions).
- `sts_endpoint_id` — ID of the STS interface endpoint.
- `kinesis_endpoint_id` — ID of the Kinesis Streams interface endpoint.
