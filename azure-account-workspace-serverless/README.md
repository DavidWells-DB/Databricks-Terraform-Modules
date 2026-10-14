# azure-account-workspace-serverless

Creates a true **serverless** Azure Databricks workspace — the distinct ARM workspace type with `properties.computeMode = "Serverless"`, created via the ARM API with the `azapi` provider. All workloads run on serverless compute; the workspace ships with managed default storage and Unity Catalog enabled automatically.

> **Correction note (v1.0.0).** v0.1.0 of this module was wrong: it used `azurerm_databricks_workspace` with no `custom_parameters` and claimed that "no VNet injection + premium SKU" makes a serverless workspace. It does not — that combination deploys a Classic (**managed-VNet / Hybrid**) workspace. A workspace is only serverless if it is created with `properties.computeMode = "Serverless"` (required on create, immutable after). `azurerm_databricks_workspace` cannot express this, which is why this module now uses `azapi_resource`. Anyone who deployed v0.1.0 has a managed-VNet workspace; because `computeMode` cannot be changed, it must be **recreated**, not imported or converted.

## What this module abstracts

A serverless-workspace-type deployment: `azapi_resource` of `Microsoft.Databricks/workspaces@2026-01-01` with `properties.computeMode = "Serverless"` and `sku.name = "premium"` ([ARM Workspaces CreateOrUpdate, 2026-01-01](https://learn.microsoft.com/en-us/rest/api/databricks/workspaces/create-or-update?view=rest-databricks-2026-01-01); [Create a serverless workspace](https://learn.microsoft.com/en-us/azure/databricks/admin/workspace/serverless-workspaces)).

## When to use

- All compute will run on serverless (serverless SQL warehouses, serverless jobs/notebooks, Lakeflow pipelines).
- You want the smallest Azure footprint: no VNet, no subnets, no NSGs, **and no managed resource group or storage account in your subscription** — serverless workspaces use managed default storage.
- Account admins without permission to provision traditional cloud infrastructure can still deploy serverless workspaces (per the Learn doc above).

## When NOT to use

- You need classic cluster compute (interactive clusters, classic jobs clusters) — a serverless workspace cannot run them at all; use `azure-account-workspace` (Hybrid/Classic type) instead.
- You want VNet injection or a customer-managed data plane — not expressible in Serverless computeMode; the API rejects `managedResourceGroupId`, `requiredNsgRules`, and all VNet-injection `parameters` in this mode.
- You need root-DBFS or managed-disk customer-managed keys — not applicable: storage is a managed service and serverless compute uses only short-lived disks. Only managed-services CMK applies (see below).

## Minimum platform tier

**Premium** — the module hardcodes `sku.name = "premium"` in the ARM body (the API tier for serverless workspaces; there is no `sku` input to get wrong).

## Region requirement

The region must support **serverless workspaces** (not merely serverless compute) — see the [serverless availability column of the feature-region-support table](https://learn.microsoft.com/en-us/azure/databricks/resources/feature-region-support). ARM rejects unsupported regions at apply time.

## Provider configuration

This module uses only the **`azapi`** provider (`~> 2.0`). `azurerm` is deliberately absent — it has no `computeMode` argument and therefore cannot create this workspace type. Configure `azapi` at the root with a service principal or managed identity that has `Contributor` on the target resource group (ARM auth via the usual `ARM_*` environment variables; `provider "azapi" { subscription_id = ... }` if you prefer it explicit).

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Workspace resource name (3-64 chars, alphanumeric + hyphens). |
| `resource_group_id` | string | yes | ARM ID of the target resource group (`/subscriptions/<uuid>/resourceGroups/<name>`). Note: the **full ID**, not the bare name — `azapi_resource.parent_id` takes an ARM ID. |
| `location` | string | yes | Azure region; must support serverless workspaces. |
| `tags` | map(string) | no | Tags on the workspace resource. Default `{}`. |
| `public_network_access_enabled` | bool | no | `true` (default) allows public front-end access; `false` sets ARM `publicNetworkAccess = "Disabled"` (front-end Private Link only — wire the private endpoints in the root composition; until they exist the workspace is unreachable). |
| `managed_services_cmk_key_vault_key_id` | string | no | Versioned Key Vault key identifier (`https://<vault>/keys/<name>/<version>`) for managed-services encryption — the **only** customer-managed key legal in Serverless computeMode. Default `null` (platform-managed keys). |

## Outputs

| Name | Description |
|---|---|
| `workspace_id` | Numeric Databricks workspace ID (string) for the control plane. |
| `workspace_url` | `https://adb-{id}.{n}.azuredatabricks.net` — host for the workspace-scoped Databricks provider. |
| `workspace_resource_id` | ARM resource ID of the workspace (RBAC, policy, diagnostic settings, private endpoint wiring). |
| `compute_mode` | The deployed ARM `properties.computeMode` (`"Serverless"`) — lets consumers verify the workspace type live; this exact check would have caught the v0.1.0 bug. |

## What the module deliberately does NOT expose (and why)

Per the [ARM 2026-01-01 schema](https://learn.microsoft.com/en-us/rest/api/databricks/workspaces/create-or-update?view=rest-databricks-2026-01-01), the following are **not allowed in Serverless computeMode** and passing them would fail the create:

- `managedResourceGroupId` — serverless workspaces have no managed resource group (managed default storage).
- `accessConnector`, `defaultStorageFirewall` — no customer storage account to firewall.
- `requiredNsgRules`, `defaultCatalog`, all VNet-injection `parameters` — no customer data plane; UC is enabled automatically (`isUcEnabled = true`).
- `encryption.entities.managedDisk` / `diskEncryptionSetId` — no classic compute disks.

The module's interface therefore has no variables for any of these. There is nothing to configure for them.

## Customer-managed key (managed services only)

Optional managed-services CMK: pass a **versioned** key identifier. The module parses it into the ARM triple (`keyName`, `keyVaultUri`, `keyVersion`) via a regex — rotation is an explicit, reviewed change of the pinned version. A key version of `""` (latest) is not accepted; pin explicitly. The Key Vault access policy for the `AzureDatabricks` first-party service principal is a root-composition concern (see `azure-account-encryption-keys`).

## Limitations of serverless workspaces (inherited from the platform)

- **No classic compute, ever.** `computeMode` is required on create and cannot be changed — a serverless workspace stays serverless; moving to classic means recreating the workspace.
- Serverless compute and default-storage limitations apply: [serverless compute limitations](https://learn.microsoft.com/en-us/azure/databricks/compute/serverless/limitations), [default storage limitations](https://learn.microsoft.com/en-us/azure/databricks/storage/default-storage#limitations).
- Serverless compute uses environment versions, not Databricks Runtime versions.

## Tests

- `tests/plan.tftest.hcl` — mock-provider plan tests (CI): the decisive assertion is `body.properties.computeMode == "Serverless"`, plus API-version pin, premium SKU, public-network-access mapping, CMK conditional and key-ID parsing, and variable validations.
- `tests/integration.tftest.hcl` — credential-gated local apply test: applies for real and asserts the live workspace reports `properties.computeMode == "Serverless"` (the check that would have caught the v0.1.0 bug).

## References

- [Workspaces CreateOrUpdate — ARM REST API 2026-01-01](https://learn.microsoft.com/en-us/rest/api/databricks/workspaces/create-or-update?view=rest-databricks-2026-01-01) — `computeMode`, per-mode allowed properties, encryption shapes.
- [Create a serverless workspace — Azure Databricks](https://learn.microsoft.com/en-us/azure/databricks/admin/workspace/serverless-workspaces) — workspace type, portal flow, CMK scope, limitations.
- [Best practices for serverless workspaces](https://learn.microsoft.com/en-us/azure/databricks/admin/workspace/serverless-workspaces-best-practices).
- [Serverless availability by region](https://learn.microsoft.com/en-us/azure/databricks/resources/feature-region-support).
- [azapi provider](https://registry.terraform.io/providers/Azure/azapi/latest/docs).
