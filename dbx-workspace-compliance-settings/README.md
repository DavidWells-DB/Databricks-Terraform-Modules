# dbx-workspace-compliance-settings

Applies workspace-level security hardening to a Databricks workspace: Compliance Security Profile, Enhanced Security Monitoring, Automatic Cluster Update, and legacy access/DBFS controls.

## What this module abstracts

A set of five workspace-level security settings that are commonly enabled together as part of a compliance hardening baseline. The module encapsulates which settings require Enterprise tier, which require Premium tier, and the immutability constraint on the Compliance Security Profile (once enabled, it cannot be disabled).

## When to use

- You are hardening an existing workspace to meet a compliance framework (HIPAA, FedRAMP, PCI-DSS, etc.).
- You want to enforce a consistent compliance baseline across multiple workspaces via a single module call.
- You are building a workspace provisioning pipeline and want to apply compliance settings as a distinct post-provisioning step.

## When NOT to use

- You are on **Azure** — Azure Databricks compliance settings are managed via the `azurerm_databricks_workspace` resource (the `enhanced_security_compliance` block) or `azapi_update_resource`, not workspace-level Databricks provider resources. Use the `azure-account-workspace` module instead.
- You want to enable the Compliance Security Profile but have not yet set up Unity Catalog with a default catalog — `disable_legacy_access` requires UC to be configured first.
- You need to *disable* the Compliance Security Profile — the Databricks API does not support disabling it once enabled. This is a permanent, one-way operation.

## Minimum platform tier

| Feature | Minimum tier |
|---|---|
| `compliance_security_profile_enabled` | **Enterprise** |
| `enhanced_security_monitoring_enabled` | **Enterprise** |
| `automatic_cluster_update_enabled` | **Enterprise** |
| `disable_legacy_access` | **Premium** |
| `disable_legacy_dbfs` | **Premium** |

The Databricks Terraform provider does not check tier at plan time; applying a tier-gated setting against an insufficient tier will fail at apply time. See DATABRICKS_RULES.md Rule 2.3 and 4.1.

## GovCloud notes

GovCloud (AWS) workspaces have the Compliance Security Profile auto-enabled at the platform level. Applying `compliance_security_profile_enabled = true` against a GovCloud workspace is a no-op — the API accepts it but the setting was already active. A `precondition` block can be added at the root composition to skip this module on GovCloud if desired.

## Provider configuration

This module uses only the workspace-level Databricks provider (surface: `Workspace`). The caller configures a `databricks` provider pointed at the workspace host URL and passes it to the module implicitly (single provider, no `configuration_aliases` required).

```hcl
provider "databricks" {
  host          = "<workspace-url>"
  client_id     = var.client_id
  client_secret = var.client_secret
}
```

The workspace provider must be authenticated as a workspace admin or account admin.

## Compliance Security Profile — permanence warning

`databricks_compliance_security_profile_workspace_setting` is a **one-way operation**. Once `is_enabled = true` is applied, the Compliance Security Profile cannot be disabled via Terraform or the API. Plan carefully before enabling in production. The Databricks documentation states: "This setting can NOT be disabled once it is enabled."

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.73 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks"></a> [databricks](#provider\_databricks) | >= 1.73 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_automatic_cluster_update_workspace_setting.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/automatic_cluster_update_workspace_setting) | resource |
| [databricks_compliance_security_profile_workspace_setting.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/compliance_security_profile_workspace_setting) | resource |
| [databricks_disable_legacy_access_setting.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/disable_legacy_access_setting) | resource |
| [databricks_disable_legacy_dbfs_setting.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/disable_legacy_dbfs_setting) | resource |
| [databricks_enhanced_security_monitoring_workspace_setting.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/enhanced_security_monitoring_workspace_setting) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_automatic_cluster_update_enabled"></a> [automatic\_cluster\_update\_enabled](#input\_automatic\_cluster\_update\_enabled) | Enable Automatic Cluster Update on the workspace. Keeps clusters patched during a maintenance window. | `bool` | `false` | no |
| <a name="input_automatic_cluster_update_maintenance_window"></a> [automatic\_cluster\_update\_maintenance\_window](#input\_automatic\_cluster\_update\_maintenance\_window) | Optional maintenance window for automatic cluster updates. Only used when automatic\_cluster\_update\_enabled = true. day\_of\_week: MONDAY–SUNDAY (uppercase). frequency: EVERY\_WEEK, FIRST\_OF\_MONTH, SECOND\_OF\_MONTH, THIRD\_OF\_MONTH, FOURTH\_OF\_MONTH, FIRST\_AND\_THIRD\_OF\_MONTH, SECOND\_AND\_FOURTH\_OF\_MONTH. hours: 0–23 (UTC). minutes: 0–59. | <pre>object({<br/>    week_day_based_schedule = optional(object({<br/>      day_of_week = string<br/>      frequency   = string<br/>      window_start_time = object({<br/>        hours   = number<br/>        minutes = number<br/>      })<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_automatic_cluster_update_restart_even_if_no_updates_available"></a> [automatic\_cluster\_update\_restart\_even\_if\_no\_updates\_available](#input\_automatic\_cluster\_update\_restart\_even\_if\_no\_updates\_available) | When automatic\_cluster\_update\_enabled = true, force a restart during the maintenance window even if no updates are available. | `bool` | `false` | no |
| <a name="input_compliance_security_profile_enabled"></a> [compliance\_security\_profile\_enabled](#input\_compliance\_security\_profile\_enabled) | Enable the Compliance Security Profile on the workspace. WARNING: this change is permanent and cannot be reversed once applied. | `bool` | `false` | no |
| <a name="input_compliance_standards"></a> [compliance\_standards](#input\_compliance\_standards) | List of compliance standards to enable. Only meaningful when compliance\_security\_profile\_enabled = true. Valid values: CANADA\_PROTECTED\_B, CYBER\_ESSENTIAL\_PLUS, FEDRAMP\_HIGH, FEDRAMP\_IL5, FEDRAMP\_MODERATE, GERMANY\_C5, GERMANY\_TISAX, HIPAA, HITRUST, IRAP\_PROTECTED, ISMAP, ITAR\_EAR, K\_FSI, NONE, PCI\_DSS. | `list(string)` | `[]` | no |
| <a name="input_disable_legacy_access"></a> [disable\_legacy\_access](#input\_disable\_legacy\_access) | Disable legacy access on the workspace. Disables direct Hive Metastore access, external location fallback, and Databricks Runtime < 13.3 LTS. Requires Unity Catalog with a default catalog configured. | `bool` | `false` | no |
| <a name="input_disable_legacy_dbfs"></a> [disable\_legacy\_dbfs](#input\_disable\_legacy\_dbfs) | Disable legacy DBFS on the workspace. Prevents use of the root DBFS storage for new workloads. | `bool` | `false` | no |
| <a name="input_enhanced_security_monitoring_enabled"></a> [enhanced\_security\_monitoring\_enabled](#input\_enhanced\_security\_monitoring\_enabled) | Enable Enhanced Security Monitoring on the workspace. Automatically enabled when compliance\_security\_profile\_enabled = true. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_automatic_cluster_update_enabled"></a> [automatic\_cluster\_update\_enabled](#output\_automatic\_cluster\_update\_enabled) | Whether Automatic Cluster Update was applied by this module. |
| <a name="output_compliance_security_profile_enabled"></a> [compliance\_security\_profile\_enabled](#output\_compliance\_security\_profile\_enabled) | Whether the Compliance Security Profile was applied by this module. True when compliance\_security\_profile\_enabled = true. Useful as a signal for downstream modules that need to know whether CSP is active. |
| <a name="output_compliance_standards"></a> [compliance\_standards](#output\_compliance\_standards) | Compliance standards passed to the Compliance Security Profile. Empty list when compliance\_security\_profile\_enabled = false. |
| <a name="output_enhanced_security_monitoring_enabled"></a> [enhanced\_security\_monitoring\_enabled](#output\_enhanced\_security\_monitoring\_enabled) | Whether Enhanced Security Monitoring was applied by this module. |
| <a name="output_legacy_access_disabled"></a> [legacy\_access\_disabled](#output\_legacy\_access\_disabled) | Whether legacy access was disabled by this module. |
| <a name="output_legacy_dbfs_disabled"></a> [legacy\_dbfs\_disabled](#output\_legacy\_dbfs\_disabled) | Whether legacy DBFS was disabled by this module. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Invalid `compliance_standards` value is rejected by variable validation.
- Invalid maintenance window `day_of_week` is rejected.
- Invalid maintenance window `frequency` is rejected.
- Invalid maintenance window `hours` (out of range) is rejected.
- Invalid maintenance window `minutes` (out of range) is rejected.
- When all feature flags are false, no resources are created.
- When `compliance_security_profile_enabled = true`, the CSP resource is planned.
- When `automatic_cluster_update_enabled = true` with a maintenance window, resource attributes match inputs.
- Output booleans reflect the set of enabled features.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks workspace) verifies actual setting creation. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
