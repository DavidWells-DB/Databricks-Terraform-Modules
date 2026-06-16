# Example: basic

Minimum invocation of the `dbx-workspace-ip-access-list` module. Enables IP access list enforcement and creates an ALLOW list for corporate networks.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks workspace URL and service principal credentials.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks.workspace` provider at the root and passing the alias to the module.
- Creating an ALLOW-only configuration (no block list).
- Using custom label and CIDR inputs.

## Optional: adding a block list

Uncomment the `block_list_cidrs` and `block_list_label` lines in `main.tf` to also create a BLOCK list. Block list entries take precedence over the allow list.

## Outputs

- `allow_list_id` — Databricks IP access list ID for the ALLOW list.
- `block_list_id` — null in this example (no block list configured).
