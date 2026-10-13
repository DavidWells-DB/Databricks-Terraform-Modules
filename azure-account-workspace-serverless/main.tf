# A true serverless workspace: ARM properties.computeMode = "Serverless".
# azurerm_databricks_workspace cannot create this workspace type — it exposes no
# computeMode argument and always deploys the Classic (managed-VNet) type, which is
# what v0.1.0 of this module shipped by mistake. This resource targets the ARM API
# directly.
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
      # Serverless workspaces require the premium tier.
      name = "premium"
    }
    properties = {
      # Required on create, immutable after. "Serverless" = every workload runs on
      # serverless compute with managed default storage and UC auto-enabled;
      # "Hybrid" = the classic managed-VNet workspace.
      computeMode = "Serverless"

      # "Disabled" = front-end reachable only via Private Link; the private
      # endpoints themselves are wired by the root composition.
      publicNetworkAccess = var.public_network_access_enabled ? "Enabled" : "Disabled"

      # Managed-services CMK is the only customer-managed key legal in Serverless
      # computeMode: root storage is a managed service and managed-disk CMK is
      # rejected by the API. The whole block is omitted when no key is supplied.
      encryption = local.managed_services_cmk != null ? {
        entities = {
          managedServices = {
            keySource = "Microsoft.Keyvault"
            keyVaultProperties = {
              keyName     = local.managed_services_cmk[1]
              keyVaultUri = "https://${local.managed_services_cmk[0]}"
              keyVersion  = local.managed_services_cmk[2]
            }
          }
        }
      } : null
    }
  }

  response_export_values = {
    workspace_id  = "properties.workspaceId"
    workspace_url = "properties.workspaceUrl"
    compute_mode  = "properties.computeMode"
  }
}
