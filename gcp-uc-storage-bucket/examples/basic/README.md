# Example: basic

Minimum invocation of the `gcp-uc-storage-bucket` module — a dedicated GCS bucket for a Unity Catalog catalog's managed storage.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in the project ID and a globally unique bucket name.
2. Configure GCP credentials (application default or a key file for the google provider).
3. Run:

   ```
   terraform init
   terraform apply
   ```

4. The `storage_root` output (`gs://<bucket>`) is what a Unity Catalog catalog consumes as its managed-storage root.

## Clean-up

```
terraform destroy
```

Note: with `force_destroy = false` (the default) the destroy fails if the bucket holds objects — drain it first or set the variable deliberately.
