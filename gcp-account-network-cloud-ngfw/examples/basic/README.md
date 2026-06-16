# Example: basic

Minimum invocation of the `gcp-account-network-cloud-ngfw` module against a GCP organization.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your GCP organization ID, project ID, and VPC network self-link.
2. Ensure GCP credentials are available (via `GOOGLE_CREDENTIALS`, `gcloud auth application-default login`, or a service account key).
3. Enable required APIs in the project:
   - `networksecurity.googleapis.com`
   - `compute.googleapis.com`
4. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `google` provider at the root with a project and region.
- Passing organization ID, project ID, zone, and VPC network self-link to the module.
- Using default severity overrides (ALERT on INFORMATIONAL, DENY on CRITICAL) as a starting point.

## Note on apply time

The `google_network_security_firewall_endpoint` resource can take up to 60 minutes to become ACTIVE. Terraform waits automatically; plan for a long `terraform apply` on first deployment.

## Outputs

- `security_profile_group_id` — Reference this in network firewall policy rules to activate threat prevention.
- `firewall_endpoint_id` — The Cloud NGFW endpoint ID.
- `firewall_endpoint_association_id` — The association binding the endpoint to the VPC.
