# ---------------------------------------------------------------------------
# Azure Key Vault
# Premium SKU is required for HSM-backed keys and Databricks CMK support.
# Purge protection is mandatory when used with Databricks: without it, a
# deleted vault cannot be recovered, leaving workspaces permanently broken.
# AzureServices bypass is required so that the Databricks control plane
# can access the Key Vault even when network ACLs restrict default access.
# ---------------------------------------------------------------------------

#tfsec:ignore:azure-keyvault-specify-network-acl
resource "azurerm_key_vault" "this" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = true
  rbac_authorization_enabled = false

  # default_action defaults to "Deny" for security compliance.
  # AzureServices bypass allows the Databricks control plane to access the vault.
  # Provide ip_rules or virtual_network_subnet_ids to allow additional sources.
  network_acls {
    default_action             = var.network_acls.default_action
    bypass                     = var.network_acls.bypass
    ip_rules                   = var.network_acls.ip_rules
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Access policy: Terraform operator
# Grants the service principal running Terraform the key management
# permissions needed to create, rotate, and delete the CMK keys.
# ---------------------------------------------------------------------------

resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = var.tenant_id
  object_id    = var.azure_client_object_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "GetRotationPolicy",
    "List",
    "Purge",
    "Recover",
    "Update",
    "WrapKey",
    "UnwrapKey",
  ]
}

# ---------------------------------------------------------------------------
# Access policy: Databricks service principal
# The AzureDatabricks first-party application needs Get, WrapKey, and
# UnwrapKey on each key so the control plane can perform envelope encryption.
# Source: https://learn.microsoft.com/en-us/azure/databricks/security/keys/customer-managed-keys
# ---------------------------------------------------------------------------

resource "azurerm_key_vault_access_policy" "databricks" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = var.tenant_id
  object_id    = var.databricks_service_principal_object_id

  key_permissions = [
    "Get",
    "UnwrapKey",
    "WrapKey",
  ]
}

# ---------------------------------------------------------------------------
# CMK: Managed Services
# Encrypts workspace objects stored in the Databricks control plane:
# notebooks, secrets, Databricks SQL queries, AI/BI dashboards, query history.
#
# RSA-HSM key type: uses the Premium SKU's HSM protection for stronger
# key material security. Requires Premium SKU on the Key Vault.
#
# No expiry date is set. An expired key renders the workspace inaccessible
# and unrecoverable. Key rotation is managed via rotation_policy or by
# creating a new key version and updating workspace arguments.
# ---------------------------------------------------------------------------
#tfsec:ignore:azure-keyvault-ensure-key-expiry
resource "azurerm_key_vault_key" "managed_services" {
  #checkov:skip=CKV_AZURE_40:Databricks CMK keys must not have an expiry date. An expired key renders the workspace inaccessible and unrecoverable.
  name         = "databricks-managed-services"
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA-HSM"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [
    azurerm_key_vault_access_policy.terraform,
    azurerm_key_vault_access_policy.databricks,
  ]
}

# ---------------------------------------------------------------------------
# CMK: Workspace Storage (DBFS root)
# Encrypts the workspace's root Blob storage account (DBFS root),
# job results, Databricks SQL results, and other workspace system data.
# RSA-HSM + no expiry — see managed_services note above.
# ---------------------------------------------------------------------------
#tfsec:ignore:azure-keyvault-ensure-key-expiry
resource "azurerm_key_vault_key" "workspace_storage" {
  #checkov:skip=CKV_AZURE_40:Databricks CMK keys must not have an expiry date. An expired key renders the workspace inaccessible and unrecoverable.
  name         = "databricks-workspace-storage"
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA-HSM"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [
    azurerm_key_vault_access_policy.terraform,
    azurerm_key_vault_access_policy.databricks,
  ]
}

# ---------------------------------------------------------------------------
# CMK: Managed Disk
# Encrypts temporary Azure managed disks on compute nodes (cluster VMs).
# Applies only to classic compute plane resources in the customer subscription.
# RSA-HSM + no expiry — see managed_services note above.
# ---------------------------------------------------------------------------
#tfsec:ignore:azure-keyvault-ensure-key-expiry
resource "azurerm_key_vault_key" "managed_disk" {
  #checkov:skip=CKV_AZURE_40:Databricks CMK keys must not have an expiry date. An expired key renders the workspace inaccessible and unrecoverable.
  name         = "databricks-managed-disk"
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA-HSM"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [
    azurerm_key_vault_access_policy.terraform,
    azurerm_key_vault_access_policy.databricks,
  ]
}

# ---------------------------------------------------------------------------
# Optional: Private Endpoint for Key Vault
# When var.private_endpoint is set, creates a private endpoint so Key Vault
# traffic stays within the VNet. Also creates a private DNS zone for
# privatelink.vaultcore.azure.net and links it to the provided VNet.
# ---------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "key_vault" {
  count = var.private_endpoint != null ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = local.pe_resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  count = var.private_endpoint != null ? 1 : 0

  name                  = "${var.key_vault_name}-dns-link"
  resource_group_name   = local.pe_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = var.private_endpoint.vnet_id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_private_endpoint" "key_vault" {
  count = var.private_endpoint != null ? 1 : 0

  name                = "${var.key_vault_name}-pe"
  location            = var.location
  resource_group_name = local.pe_resource_group_name
  subnet_id           = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "${var.key_vault_name}-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "key-vault-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault[0].id]
  }

  tags = var.tags
}
