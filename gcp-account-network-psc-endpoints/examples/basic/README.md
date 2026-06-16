# Example: basic

Minimum invocation of the `gcp-account-network-psc-endpoints` module for a GCP project in `us-central1`.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your GCP project details and Databricks account credentials.
2. Ensure the `google` provider is authenticated (via Application Default Credentials, service account key, or Workload Identity).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring both `google` and `databricks.account` providers at the root.
- Passing the `databricks.account` provider alias to the module.
- Using the module's built-in PSC service attachment URI map for `us-central1` (no override needed).
- Creating PSC endpoints with `public_access_enabled = true` and `private_access_level = ACCOUNT` (workspaces accessible privately and publicly; all account VPC endpoints allowed).

## Outputs

- `workspace_psc_endpoint_id` — Databricks VPC endpoint ID for the workspace PSC rule; pass to a workspace creation module.
- `relay_psc_endpoint_id` — Databricks VPC endpoint ID for the SCC relay PSC rule.
- `private_access_settings_id` — Pass to a workspace creation module as `private_access_settings_id`.
- `workspace_psc_ip` — Internal IP of the workspace forwarding rule (verify with `nslookup <workspace-url>`).
- `relay_psc_ip` — Internal IP of the SCC relay forwarding rule.
