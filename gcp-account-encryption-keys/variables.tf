variable "project_id" {
  type        = string
  description = "GCP project for the key ring and crypto key."
  nullable    = false
}

variable "location" {
  type        = string
  description = "KMS location, normally the workspace region."
  nullable    = false
}

variable "key_ring_name" {
  type        = string
  description = "Cloud KMS key-ring creation name."
  nullable    = false
}

variable "crypto_key_name" {
  type        = string
  description = "Cloud KMS crypto-key creation name."
  nullable    = false
}

variable "rotation_period" {
  type        = string
  description = "Optional automatic rotation period such as 7776000s (90 days). Null disables automatic rotation."
  default     = null
}

variable "accessor_members" {
  type        = set(string)
  description = "IAM members granted roles/cloudkms.cryptoKeyEncrypterDecrypter, for example serviceAccount:provisioner@project.iam.gserviceaccount.com."
  default     = []
}
