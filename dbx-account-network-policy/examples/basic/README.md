# Basic Example: Account Network Policy

This example demonstrates creating a Databricks account-level network policy that restricts serverless compute egress.

## Features

- Creates a network policy with `ALLOW_LIST` egress mode
- Allows specific internet destinations (private network ranges and PyPI)
- Allows access to specific S3 bucket for data operations

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and populate with your values:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Initialize and apply:
   ```bash
   terraform init
   terraform apply
   ```

## Requirements

- Databricks Premium tier or higher
- Account admin permissions
- Databricks account-level service principal with OAuth M2M credentials

## Outputs

- `network_policy_id`: Policy ID to reference in workspace or serverless configurations
- `policy_name`: Name of the created policy
- `egress_mode`: Configured egress mode (ALLOW_LIST)
