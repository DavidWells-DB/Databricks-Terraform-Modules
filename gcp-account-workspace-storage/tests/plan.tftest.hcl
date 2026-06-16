mock_provider "google" {}

mock_provider "databricks" {
  alias = "account"
}

variables {
  databricks_account_id            = "00000000-0000-0000-0000-000000000000"
  project_id                       = "my-test-project"
  region                           = "us-central1"
  resource_prefix                  = "test-prefix"
  databricks_service_account_email = "databricks-sa@my-test-project.iam.gserviceaccount.com"
}

run "bucket_name_derived_from_resource_prefix" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.name == "test-prefix-root-storage"
    error_message = "Bucket name should be <resource_prefix>-root-storage"
  }
}

run "storage_config_name_derived_from_resource_prefix" {
  command = plan

  assert {
    condition     = databricks_mws_storage_configurations.this.storage_configuration_name == "test-prefix-storage"
    error_message = "Storage configuration name should be <resource_prefix>-storage"
  }
}

run "storage_config_uses_input_account_id" {
  command = plan

  assert {
    condition     = databricks_mws_storage_configurations.this.account_id == "00000000-0000-0000-0000-000000000000"
    error_message = "Storage configuration account_id should match the databricks_account_id input"
  }
}

run "object_admin_iam_member_uses_correct_role" {
  command = plan

  assert {
    condition     = google_storage_bucket_iam_member.object_admin.role == "roles/storage.objectAdmin"
    error_message = "object_admin IAM member should use roles/storage.objectAdmin"
  }
}

run "legacy_bucket_reader_iam_member_uses_correct_role" {
  command = plan

  assert {
    condition     = google_storage_bucket_iam_member.legacy_bucket_reader.role == "roles/storage.legacyBucketReader"
    error_message = "legacy_bucket_reader IAM member should use roles/storage.legacyBucketReader"
  }
}

run "iam_members_use_service_account_email" {
  command = plan

  assert {
    condition     = google_storage_bucket_iam_member.object_admin.member == "serviceAccount:databricks-sa@my-test-project.iam.gserviceaccount.com"
    error_message = "object_admin IAM member should reference the databricks_service_account_email input"
  }

  assert {
    condition     = google_storage_bucket_iam_member.legacy_bucket_reader.member == "serviceAccount:databricks-sa@my-test-project.iam.gserviceaccount.com"
    error_message = "legacy_bucket_reader IAM member should reference the databricks_service_account_email input"
  }
}

run "bucket_has_uniform_access" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.uniform_bucket_level_access == true
    error_message = "GCS bucket should have uniform_bucket_level_access enabled"
  }
}

run "bucket_in_correct_region" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.location == "us-central1"
    error_message = "Bucket location should match the region input"
  }
}

run "kms_encryption_disabled_by_default" {
  command = plan

  assert {
    condition     = length(google_storage_bucket.this.encryption) == 0
    error_message = "Encryption block should be empty when kms_key_name is null"
  }
}

run "kms_encryption_enabled_when_key_provided" {
  command = plan

  variables {
    kms_key_name = "projects/my-test-project/locations/us-central1/keyRings/my-ring/cryptoKeys/my-key"
  }

  assert {
    condition     = length(google_storage_bucket.this.encryption) == 1
    error_message = "Encryption block should be present when kms_key_name is set"
  }
}

run "resource_prefix_too_long_rejected" {
  command = plan

  variables {
    resource_prefix = "this-prefix-is-way-too-long-and-exceeds-the-38-char-limit-by-a-lot"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_uppercase_rejected" {
  command = plan

  variables {
    resource_prefix = "InvalidPrefix"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_leading_hyphen_rejected" {
  command = plan

  variables {
    resource_prefix = "-leading-hyphen"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_trailing_hyphen_rejected" {
  command = plan

  variables {
    resource_prefix = "trailing-hyphen-"
  }

  expect_failures = [var.resource_prefix]
}

run "invalid_service_account_email_rejected" {
  command = plan

  variables {
    databricks_service_account_email = "not-a-service-account@gmail.com"
  }

  expect_failures = [var.databricks_service_account_email]
}

run "invalid_kms_key_name_rejected" {
  command = plan

  variables {
    kms_key_name = "not/a/valid/kms/key/path"
  }

  expect_failures = [var.kms_key_name]
}
