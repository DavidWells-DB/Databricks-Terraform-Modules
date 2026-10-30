# A classic (Hybrid) Azure Databricks workspace, created directly via the ARM API.
#
# WHY azapi, not azurerm_databricks_workspace: the workspace catalog. ARM's
# properties.defaultCatalog.initialType defaults to "HiveMetastore" and the
# azurerm provider exposes no argument for it at all, so every workspace azurerm
# creates ships with its default namespace pointing at the legacy hive_metastore
# catalog instead of a Unity Catalog catalog. Setting initialType = "UnityCatalog"
# at creation makes the platform provision a workspace catalog (named after the
# workspace) and set it as the workspace default catalog. The field exists ONLY
# in the create request — it cannot be patched onto an existing workspace — so
# the creation itself must go through azapi.
# https://learn.microsoft.com/en-us/rest/api/databricks/workspaces/create-or-update?view=rest-databricks-2026-01-01
resource "azapi_resource" "this" {
  type      = "Microsoft.Databricks/workspaces@2026-01-01"
  name      = var.name
  parent_id = var.resource_group_id
  location  = var.location
  tags      = var.tags

  # The 2026-01-01 API version postdates the ARM schemas azapi bundles for this
  # resource type, so the provider cannot validate the body shape. The plan
  # tests are the guardrail against body typos.
  schema_validation_enabled = false

  body = {
    sku = {
      name = var.sku
    }

    properties = {
      # "Hybrid" = the classic managed-VNet workspace this module has always
      # created (azurerm sends the identical value). Required on create, cannot
      # be changed afterwards.
      computeMode = "Hybrid"

      # ARM requires the full resource-group ID in Hybrid mode. azurerm filled
      # this in from the caller's subscription; here it is derived from the
      # parent resource group (data lookup) with azurerm's default name
      # (databricks-rg-<resource-group-name>) when none is supplied.
      managedResourceGroupId = local.managed_resource_group_id

      # The workspace catalog: platform-created, named after the workspace,
      # bound only to this workspace, and set as the workspace default catalog.
      # initialName is deliberately omitted — the API then uses the workspace
      # name, which keeps the catalog aligned with resource_prefix naming.
      defaultCatalog = {
        initialType = "UnityCatalog"
      }

      publicNetworkAccess = var.public_network_access_enabled ? "Enabled" : "Disabled"

      # NSG rule enforcement. Null defers to the ARM default (AllRules), the
      # same way azurerm omitted the field when the variable was null.
      requiredNsgRules = var.network_security_group_rules_required

      # VNet injection + encryption-prep booleans — ARM's WorkspaceCustomParameters
      # are WRAPPED objects ({type, value}), unlike the azurerm arguments.
      # Sent only when at least one is set; azurerm always sent prepareEncryption
      # (with value true or false) — sending it only when true is equivalent,
      # false being the API default.
      parameters = local.parameters_needed ? local.parameters : null

      # Managed-services / managed-disk CMK at the workspace level. Whole
      # entities block omitted when no key is supplied (identical to azurerm,
      # which built the entities only from the two key-id variables).
      encryption = local.encryption_entities != null ? {
        entities = local.encryption_entities
      } : null

      # Enhanced Security and Compliance add-on. Omitted entirely when all
      # three flags are off (azurerm's dynamic block behaved the same).
      enhancedSecurityCompliance = local.esc_needed ? {
        enhancedSecurityMonitoring = {
          value = var.enhanced_security_monitoring_enabled ? "Enabled" : "Disabled"
        }
        automaticClusterUpdate = {
          value = var.automatic_cluster_update_enabled ? "Enabled" : "Disabled"
        }
        complianceSecurityProfile = {
          value               = var.compliance_security_profile_enabled ? "Enabled" : "Disabled"
          complianceStandards = var.compliance_security_profile_enabled ? var.compliance_security_profile_standards : null
        }
      } : null

      # Default storage firewall (premium). azurerm looked the connector up via
      # API to fill identityType; azapi has no such lookup, so the identity type
      # is an explicit input defaulting to SystemAssigned.
      defaultStorageFirewall = var.default_storage_firewall_enabled ? "Enabled" : null
      accessConnector = var.default_storage_firewall_enabled ? {
        id                     = var.access_connector_id
        identityType           = var.access_connector_identity_type
        userAssignedIdentityId = var.access_connector_identity_type == "UserAssigned" ? var.access_connector_user_assigned_identity_id : null
      } : null
    }
  }

  response_export_values = {
    workspace_id              = "properties.workspaceId"
    workspace_url             = "properties.workspaceUrl"
    managed_resource_group_id = "properties.managedResourceGroupId"
    storage_account_identity  = "properties.storageAccountIdentity"
    managed_disk_identity     = "properties.managedDiskIdentity"
    disk_encryption_set_id    = "properties.diskEncryptionSetId"
    is_uc_enabled             = "properties.isUcEnabled"
    compute_mode              = "properties.computeMode"
  }

  lifecycle {
    # VNet injection completeness — azurerm enforced this at the provider
    # boundary; azapi cannot, so it is mirrored here. Referencing the
    # association IDs also keeps them part of this resource's evaluation, which
    # is what orders the workspace create AFTER the NSG associations in the
    # caller's graph.
    precondition {
      condition = !local.vnet_injection_enabled || (
        var.host_subnet_name != null &&
        var.container_subnet_name != null &&
        var.public_subnet_network_security_group_association_id != null &&
        var.private_subnet_network_security_group_association_id != null
      )
      error_message = "virtual_network_id, host_subnet_name, container_subnet_name, public_subnet_network_security_group_association_id, and private_subnet_network_security_group_association_id must ALL be set together for VNet injection."
    }

    # CSP forces the rest of the add-on on — azurerm's create-time validation,
    # mirrored. Off-flips fail at PLAN time with the reason, not at apply.
    precondition {
      condition = !var.compliance_security_profile_enabled || (
        var.enhanced_security_monitoring_enabled &&
        var.automatic_cluster_update_enabled
      )
      error_message = "compliance_security_profile_enabled = true requires enhanced_security_monitoring_enabled = true and automatic_cluster_update_enabled = true (the Compliance Security Profile forces the whole Enhanced Security and Compliance add-on on)."
    }

    # Premium-tier requirement for every workspace-argument hardening feature —
    # azurerm's create-time validation, mirrored.
    precondition {
      condition = var.sku == "premium" || !(
        var.customer_managed_key_enabled ||
        var.infrastructure_encryption_enabled ||
        var.default_storage_firewall_enabled ||
        var.compliance_security_profile_enabled ||
        var.enhanced_security_monitoring_enabled ||
        var.automatic_cluster_update_enabled ||
        var.managed_services_cmk_key_vault_key_id != null ||
        var.managed_disk_cmk_key_vault_key_id != null
      )
      error_message = "CMK, infrastructure encryption, the default storage firewall, and the Enhanced Security and Compliance add-on all require sku = \"premium\"."
    }

    # Managed-services CMK is prepared (prepareEncryption) only when
    # customer_managed_key_enabled is set — azurerm's schema-level requirement.
    precondition {
      condition     = var.managed_services_cmk_key_vault_key_id == null || var.customer_managed_key_enabled
      error_message = "managed_services_cmk_key_vault_key_id requires customer_managed_key_enabled = true (the key must be prepared for at creation via prepareEncryption)."
    }
  }
}

# Root DBFS customer-managed key — applied as a post-creation step because the
# workspace must exist before the CMK association can be registered.
resource "azurerm_databricks_workspace_root_dbfs_customer_managed_key" "this" {
  count = local.root_dbfs_cmk_enabled ? 1 : 0

  workspace_id     = azapi_resource.this.id
  key_vault_key_id = var.root_dbfs_cmk_key_vault_key_id
  key_vault_id     = var.root_dbfs_cmk_key_vault_id
}

# Extended compliance standards (HITRUST, IRAP_PROTECTED, UK_CYBER_ESSENTIALS_PLUS,
# CANADA_PROTECTED_B) were never supported by the azurerm allowlist and are applied
# via the ARM REST API. azapi_update_resource patches the workspace in-place without
# replacing it. Per module candidates notes and the Databricks module rules Rule 3.2.
resource "azapi_update_resource" "compliance_standards" {
  count = local.azapi_compliance_needed ? 1 : 0

  type        = "Microsoft.Databricks/workspaces@2023-09-15-preview"
  resource_id = azapi_resource.this.id

  body = {
    properties = {
      enhancedSecurityCompliance = {
        complianceSecurityProfile = {
          value               = "Enabled"
          complianceStandards = local.all_compliance_standards
        }
      }
    }
  }

  depends_on = [azapi_resource.this]
}
