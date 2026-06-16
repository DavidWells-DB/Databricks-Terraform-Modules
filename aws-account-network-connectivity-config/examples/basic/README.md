# Example: basic

Minimum invocation of the `aws-account-network-connectivity-config` module against a commercial AWS account.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks account ID and service principal credentials.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks.account` provider at the root.
- Passing the `databricks.account` provider alias to the module.
- Creating a single NCC in `us-east-1` for a commercial (non-GovCloud) deployment.

## Outputs

- `network_connectivity_config_id` — Pass to a `databricks_mws_ncc_binding` resource to attach this NCC to a workspace.
- `name` — The name of the registered NCC (useful for cross-referencing and auditing).
