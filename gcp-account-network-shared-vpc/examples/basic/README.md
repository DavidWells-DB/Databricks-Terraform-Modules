# Example: basic

Minimum invocation of the `gcp-account-network-shared-vpc` module. Configures one host project, attaches one service project, and grants `roles/compute.networkUser` on a named subnet to a Databricks service account.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your GCP project IDs, subnet name, and service account email.
2. Authenticate to GCP (via `gcloud auth application-default login`, a service account key, or Workload Identity).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `google` provider at the root composition.
- Attaching a service project to the Shared VPC host.
- Granting `roles/compute.networkUser` on a specific subnet to a Databricks service account from the service project.

## Outputs

- `host_project_id` — The configured Shared VPC host project ID.
- `service_project_attachment_ids` — Map of service project IDs to their Shared VPC attachment resource IDs.
