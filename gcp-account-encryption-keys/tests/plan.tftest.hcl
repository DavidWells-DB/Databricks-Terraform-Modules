mock_provider "google" {}

variables {
  project_id      = "my-gcp-project"
  location        = "us-central1"
  key_ring_name   = "customer-ring"
  crypto_key_name = "customer-key"
}

run "named_key_creation_without_bindings" {
  command = plan

  assert {
    condition     = google_kms_key_ring.this.name == "customer-ring" && google_kms_crypto_key.this.name == "customer-key"
    error_message = "Explicit key-ring and crypto-key names must be used exactly"
  }
  assert {
    condition     = length(google_kms_crypto_key_iam_member.accessor) == 0 && google_kms_crypto_key.this.rotation_period == null
    error_message = "Bindings and automatic rotation must be optional"
  }
}

run "accessor_bindings_and_rotation" {
  command = plan

  variables {
    rotation_period  = "7776000s"
    accessor_members = ["serviceAccount:provisioner@my-gcp-project.iam.gserviceaccount.com"]
  }

  assert {
    condition     = google_kms_crypto_key.this.rotation_period == "7776000s" && google_kms_crypto_key_iam_member.accessor["serviceAccount:provisioner@my-gcp-project.iam.gserviceaccount.com"].role == "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    error_message = "Rotation and explicit accessor bindings must reach the key resources"
  }
}
