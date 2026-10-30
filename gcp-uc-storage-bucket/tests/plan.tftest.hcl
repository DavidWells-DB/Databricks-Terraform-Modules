mock_provider "google" {
  mock_resource "google_storage_bucket" {
    defaults = {
      name = "my-catalog-uc"
    }
  }
}

variables {
  bucket_name = "my-catalog-uc"
}

run "bucket_created_with_input_name" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.name == "my-catalog-uc" && google_storage_bucket.this.force_destroy == false
    error_message = "Bucket should use the bucket_name input; force_destroy defaults to false"
  }
}

run "uniform_access_and_public_prevention_on" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.uniform_bucket_level_access == true && google_storage_bucket.this.public_access_prevention == "enforced"
    error_message = "Uniform bucket-level access and public access prevention must both be enforced — UC storage is accessed via the credential's service account only"
  }
}

run "storage_root_output_format" {
  command = plan

  assert {
    condition     = output.storage_root == "gs://my-catalog-uc"
    error_message = "storage_root should be gs://<bucket-name>"
  }
}

run "invalid_bucket_name_rejected" {
  command = plan

  variables {
    bucket_name = "Bad_Bucket!"
  }

  expect_failures = [var.bucket_name]
}

run "too_short_bucket_name_rejected" {
  command = plan

  variables {
    bucket_name = "ab"
  }

  expect_failures = [var.bucket_name]
}
