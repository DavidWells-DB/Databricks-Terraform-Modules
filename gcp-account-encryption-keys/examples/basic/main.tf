terraform {
  required_version = ">= 1.7"
}

module "encryption_keys" {
  source = "../../"

  project_id      = var.project_id
  location        = var.location
  key_ring_name   = var.key_ring_name
  crypto_key_name = var.crypto_key_name
}
