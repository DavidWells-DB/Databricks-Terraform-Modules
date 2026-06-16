# Example: basic

Minimum invocation of the `gcp-account-network-vpc` module against a GCP project.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your GCP project ID and Databricks account ID.
2. Ensure GCP credentials are available via Application Default Credentials (`gcloud auth application-default login`) or the `GOOGLE_CREDENTIALS` environment variable.
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring both `google` and `databricks.account` providers at the root.
- Passing the `databricks.account` provider alias to the module.
- Using the module with default CIDRs for a single-region GCP Databricks workspace.
- Secondary IP ranges for GKE pod and service networking.

## Outputs

- `databricks_network_id` — Pass to a workspace creation module as its `network_id` input.
- `network_self_link` — The VPC self-link (useful for Cloud NAT or PSC endpoint modules).
- `subnetwork_self_link` — The subnetwork self-link (useful for PSC endpoint modules).
