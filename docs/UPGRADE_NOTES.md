# Upgrade notes

Breaking module versions and how to migrate. Per-module details also live in each
module's `CHANGELOG.md`; this page covers the migrations that need operator action.

## azure-account-workspace-serverless v0.1.0 → v1.0.0 (2026-10-13)

**v0.1.0 was wrong about the workspace type.** It created the workspace with
`azurerm_databricks_workspace` and no `custom_parameters`, claiming that "no VNet
injection + premium SKU" makes a serverless workspace. It does not — that combination
deploys a Classic **managed-VNet** workspace (`properties.computeMode = "Hybrid"`). A
true serverless workspace on Azure is a distinct workspace type:
`properties.computeMode = "Serverless"` at create time (ARM Workspaces API
`2026-01-01`), immutable afterwards. `azurerm_databricks_workspace` cannot express it,
which is why v1.0.0+ creates the workspace via the `azapi` provider.

### Step 1 — check what you actually deployed

The v1.0.1+ module (and any config consuming it) exposes `deployed_compute_mode`.
Out-of-band equivalent:

```bash
az resource show --ids <your-workspace-resource-id> \
  --query "{computeMode: properties.computeMode, isUcEnabled: properties.isUcEnabled}"
```

- `computeMode: "Serverless"` — you are already on the true type; only the module
  interface changed (see Step 3).
- `computeMode: "Hybrid"` (or the field absent) — you have a Classic managed-VNet
  workspace from v0.1.0. Continue to Step 2.

### Step 2 — migrate a v0.1.0 workspace to the serverless type

`computeMode` **cannot be changed** — there is no conversion, no `terraform import`,
no in-place path. Migrate by replacement:

1. Anything you need from the old workspace (notebooks, jobs, tables) lives in the
   Databricks workspace — export or Repo-sync what you must keep.
2. Deploy a NEW workspace with the v1.0.x module (it is `computeMode = "Serverless"`
   by construction).
3. Move workloads/notebooks to the new workspace, repoint consumers to its URL.
4. Destroy the old workspace with the v0.1.0 config (or `az`), then remove the old
   state.

### Step 3 — interface changes when upgrading the module call

v1.0.0 is a breaking rewrite of the module's interface:

| v0.1.0 | v1.0.x |
|---|---|
| `resource_group_name` (bare name) | `resource_group_id` (full ARM ID) |
| `sku` variable (default `premium`) | removed — premium is hardcoded in the ARM body |
| `managed_resource_group_name` | removed — serverless workspaces have no managed RG |
| `access_connector_id`, `default_storage_firewall_enabled` | removed — forbidden in Serverless computeMode |
| `managed_disk_cmk_*`, `root_dbfs_cmk_*` (+ post-creation resource), `customer_managed_key_enabled`, `infrastructure_encryption_enabled` | removed — not applicable to serverless (storage is a managed service; managed-disk CMK is rejected) |
| `managed_services_cmk_key_vault_key_id` | kept — the ONLY legal customer-managed key; must be a **versioned** key identifier |
| outputs `managed_resource_group_id`, `storage_account_identity`, `managed_disk_identity`, `disk_encryption_set_id` | removed — none exist in Serverless computeMode |
| — | new `compute_mode` output (v1.0.1+): the deployed-type readback |

Drop every removed input from your module block; the v1.0.x plan will reject them if
left in place, which is deliberate (they could never apply to a serverless workspace).
