# Example: basic

Minimum invocation of the `dbx-uc-external-location` module. Registers two S3-backed external locations in Unity Catalog and assigns privileges to example groups.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks workspace URL, service principal credentials, and an existing storage credential ID.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## Prerequisites

- A Databricks workspace running at Premium tier or higher with Unity Catalog enabled.
- An existing `databricks_storage_credential` that authorizes access to the S3 locations (e.g., from the `aws-uc-storage-credential` module or created directly). Pass its ID as `aws_storage_credential_id`.

## What this example demonstrates

- Configuring the `databricks.workspace` provider at the root and passing it to the module.
- Declaring two locations with different grant sets.
- Passing per-location grants inline in the `locations` map.

## Outputs

- `external_location_ids` — map of location name to Databricks resource ID.
- `external_location_urls` — map of location name to registered cloud storage URL.
