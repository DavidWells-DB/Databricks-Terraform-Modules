# Example: basic

Minimum invocation of the `gcp-account-vpc-service-controls` module.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your GCP project, access policy ID, and protected project numbers.
2. Configure GCP credentials for the target organization (via environment variables, service account key, or Application Default Credentials).
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `google` provider at the root.
- Using the module's defaults for restricted services (Cloud Storage and BigQuery).
- Protecting one or more GCP projects with a VPC Service Controls perimeter.

## Outputs

- `perimeter_id` — Full resource name of the created service perimeter.
- `protected_projects` — Normalized list of protected project numbers.
