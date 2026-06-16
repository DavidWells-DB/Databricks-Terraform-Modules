# Example: basic

Minimum invocation of the `gcp-account-workspace` module. This example creates a classic-compute Databricks workspace on GCP using pre-existing network and storage configurations.

## Prerequisites

Before running this example, you need:
- A network configuration ID from the `gcp-account-network-vpc` module (`databricks_network_id`)
- A storage configuration ID from the `gcp-account-workspace-storage` module (`storage_configuration_id`)

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values.
2. Configure GCP credentials (via `gcloud auth application-default login` or a service account).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks.account` provider for GCP (`https://accounts.gcp.databricks.com`).
- Passing the `databricks.account` provider alias to the module.
- Wiring pre-created network and storage configuration IDs into the workspace.

## Outputs

- `workspace_id` — Numeric workspace ID. Pass to workspace-scoped modules that require a workspace ID.
- `workspace_url` — Full workspace URL. Use as `host` in the workspace-scoped Databricks provider.
- `dns_propagation_complete` — Trigger value to ensure downstream workspace providers connect only after DNS propagates.
