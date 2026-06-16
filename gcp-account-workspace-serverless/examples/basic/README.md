# Example: basic

Minimum invocation of the `gcp-account-workspace-serverless` module.

## What this example demonstrates

- Configuring the `databricks.account` provider for GCP (`https://accounts.gcp.databricks.com`).
- Passing the `databricks.account` provider alias to the module.
- Creating a serverless-only workspace with no VPC, storage configuration, or GKE setup required.

## Prerequisites

Before running this example:
1. A GCP project with the Databricks Workspace API enabled.
2. A Databricks account-level service principal with account admin permissions.
3. The GCP project must already have the Databricks provisioning service account configured (see `gcp-account-provisioning-service-account` module).

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## Outputs

- `workspace_id` — Numeric Databricks workspace ID.
- `workspace_url` — Full workspace URL (e.g. `https://<id>.gcp.databricks.com`). Use as the `host` for the workspace-scoped Databricks provider.
