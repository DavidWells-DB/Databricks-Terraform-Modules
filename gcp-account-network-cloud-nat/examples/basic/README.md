# Example: basic

Minimum invocation of the `gcp-account-network-cloud-nat` module for a private Databricks subnet.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your GCP project, network, and subnetwork details.
2. Authenticate to GCP (`gcloud auth application-default login` or set `GOOGLE_CREDENTIALS`).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `google` provider at the root with explicit project and region.
- Passing the minimum required inputs (`project_id`, `region`, `network_self_link`, `subnetwork_self_link`, `resource_prefix`) to the module.
- Using the module's defaults for `min_ports_per_vm` (64) and `log_config_enable` (false).

## Outputs

- `router_id` — Fully-qualified Cloud Router resource ID.
- `nat_id` — Fully-qualified Cloud NAT resource ID.
