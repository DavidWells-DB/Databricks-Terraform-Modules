# Example: basic

Minimum invocation of the `aws-account-workspace` module against a commercial AWS account.

## Prerequisites

Before running this example, you need the IDs of the three required Databricks registrations. These are produced by the paired modules:

- `credentials_id` — from `aws-account-workspace-credentials`
- `storage_configuration_id` — from `aws-account-workspace-storage`
- `databricks_network_id` — from `aws-account-network` or `aws-account-network-vpc`

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks account credentials and the IDs of the pre-created registrations.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks.account` provider at the root and passing it to the module via `providers`.
- Wiring the three required Databricks configuration IDs (credentials, storage, network) into the workspace.
- Using the module's defaults for a commercial (non-GovCloud) deployment (no PrivateLink, no CMK, no NCC).

## Outputs

- `workspace_id` — Numeric Databricks workspace ID.
- `workspace_url` — Full workspace URL. Use as the `host` for a workspace-scoped Databricks provider.
- `deployment_name` — Subdomain portion of the workspace URL.
