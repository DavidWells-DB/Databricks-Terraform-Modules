mock_provider "google" {}

mock_provider "databricks" {
  alias = "workspace"

  override_resource {
    target = databricks_storage_credential.this
    values = {
      id                             = "example-gcs-credential"
      name                           = "example-gcs-credential"
      databricks_gcp_service_account = { email = "databricks-sa-abc123@my-project.iam.gserviceaccount.com" }
    }
  }
}

variables {
  credential_name = "example-gcs-credential"
  bucket_name     = "my-uc-storage-bucket"
}

run "storage_credential_uses_input_name" {
  command = plan

  assert {
    condition     = databricks_storage_credential.this.name == "example-gcs-credential"
    error_message = "Storage credential name should match the credential_name input"
  }
}

run "object_admin_iam_member_targets_correct_bucket" {
  command = plan

  assert {
    condition     = google_storage_bucket_iam_member.object_admin.bucket == "my-uc-storage-bucket"
    error_message = "object_admin IAM member should target the bucket_name input"
  }
}

run "object_admin_iam_member_has_correct_role" {
  command = plan

  assert {
    condition     = google_storage_bucket_iam_member.object_admin.role == "roles/storage.objectAdmin"
    error_message = "object_admin IAM member should use roles/storage.objectAdmin"
  }
}

run "bucket_reader_iam_member_targets_correct_bucket" {
  command = plan

  assert {
    condition     = google_storage_bucket_iam_member.bucket_reader.bucket == "my-uc-storage-bucket"
    error_message = "bucket_reader IAM member should target the bucket_name input"
  }
}

run "bucket_reader_iam_member_has_correct_role" {
  command = plan

  assert {
    condition     = google_storage_bucket_iam_member.bucket_reader.role == "roles/storage.legacyBucketReader"
    error_message = "bucket_reader IAM member should use roles/storage.legacyBucketReader"
  }
}

run "credential_name_empty_rejected" {
  command = plan

  variables {
    credential_name = ""
  }

  expect_failures = [var.credential_name]
}

run "credential_name_invalid_chars_rejected" {
  command = plan

  variables {
    credential_name = "invalid name with spaces"
  }

  expect_failures = [var.credential_name]
}

run "credential_name_too_long_rejected" {
  command = plan

  variables {
    credential_name = "this-credential-name-is-way-too-long-and-exceeds-the-one-hundred-character-maximum-allowed-by-this-module"
  }

  expect_failures = [var.credential_name]
}

run "bucket_name_too_short_rejected" {
  command = plan

  variables {
    bucket_name = "ab"
  }

  expect_failures = [var.bucket_name]
}

run "bucket_name_uppercase_rejected" {
  command = plan

  variables {
    bucket_name = "MyUpperCaseBucket"
  }

  expect_failures = [var.bucket_name]
}

run "bucket_name_too_long_rejected" {
  command = plan

  variables {
    bucket_name = "this-bucket-name-is-way-too-long-and-exceeds-the-gcs-sixty-three-character-limit"
  }

  expect_failures = [var.bucket_name]
}
