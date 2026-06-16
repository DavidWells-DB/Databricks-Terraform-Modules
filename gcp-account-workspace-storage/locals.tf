locals {
  # Bucket name is derived from the resource_prefix to keep naming consistent.
  # GCS bucket names must be globally unique and <= 63 characters.
  # resource_prefix is validated to <= 38 chars; "-root-storage" adds 13 → max 51 chars total.
  bucket_name = "${var.resource_prefix}-root-storage"
}
