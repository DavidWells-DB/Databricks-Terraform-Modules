locals {
  # Parse a versioned Key Vault key identifier into [vault host, key name, key version]:
  #   https://<vault-host>/keys/<key-name>/<key-version>
  # The ARM encryption body wants the three fields separately.
  managed_services_cmk = var.managed_services_cmk_key_vault_key_id != null ? regex(
    "^https://([^/]+)/keys/([^/]+)/([^/]+)$",
    var.managed_services_cmk_key_vault_key_id,
  ) : null
}
