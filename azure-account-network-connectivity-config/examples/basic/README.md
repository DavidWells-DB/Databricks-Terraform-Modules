# Example: basic

Minimum invocation of the `azure-account-network-connectivity-config` module. Creates a Network Connectivity Config (NCC) in the `eastus` Azure region without any internet restrictions (no account network policy).

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks account ID and service principal credentials.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks.account` provider for Azure at the root.
- Passing the `databricks.account` provider alias to the module.
- Creating an NCC without an account network policy (unrestricted egress).

## Outputs

- `network_connectivity_config_id` — Pass to `databricks_mws_ncc_binding` to attach this NCC to a workspace, or supply it directly to `databricks_mws_workspaces`.
- `ncc_name` — The name registered in Databricks (useful for cross-referencing).
