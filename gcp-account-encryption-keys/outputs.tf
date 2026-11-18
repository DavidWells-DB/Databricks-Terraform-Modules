output "key_ring_id" {
  value       = google_kms_key_ring.this.id
  description = "Created key-ring ID."
}

output "crypto_key_id" {
  value       = google_kms_crypto_key.this.id
  description = "Created crypto-key ID for the GCP classic workspace cmk_key_id input."
}

output "crypto_key_name" {
  value       = google_kms_crypto_key.this.name
  description = "Created crypto-key name."
}
