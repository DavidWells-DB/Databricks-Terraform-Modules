# dbx-workspace-sql-warehouse

Creates a Databricks SQL warehouse (endpoint) in a workspace with sizing, scaling, spot policy, channel selection, and optional permissions.

## What this module abstracts

"A fully configured SQL warehouse with access control" — one cohesive unit. The `databricks_sql_endpoint` resource and its `databricks_permissions` are paired per DATABRICKS_RULES.md Rule 1.4: granting permissions immediately after creation avoids a second apply cycle and reflects the common pattern of provisioning a warehouse with known access requirements.

## When to use

- You're provisioning a new SQL warehouse in a Databricks workspace.
- You want to configure sizing, auto-scaling, spot policy, and channel in one module call.
- You need to grant initial permissions (CAN_USE, CAN_MANAGE, etc.) at creation time.

## When NOT to use

- You're managing an existing warehouse created outside Terraform — use a `data "databricks_sql_endpoint"` source at the root composition instead.
- You need advanced warehouse features not exposed as variables (custom endpoint config, specific serverless configurations) — extend this module or compose at the root level.
- You're on a Standard tier workspace — SQL warehouses require **Premium tier or higher**.

## Minimum platform tier

**Premium.** The Databricks Terraform provider does not check tier at plan time; if applied against a Standard-tier workspace, the API will reject and apply will fail. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

The module declares `configuration_aliases = [databricks.workspace]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.workspace` provider configured against the target Databricks workspace (e.g., `https://<workspace-host>`).

This module is cloud-agnostic and operates entirely at the workspace layer.

## Cluster sizing

The `cluster_size` variable accepts standard Databricks warehouse sizes:
- `2X-Small`, `X-Small`, `Small`, `Medium`, `Large`
- `X-Large`, `2X-Large`, `3X-Large`, `4X-Large`

Each size tier doubles the compute capacity of the previous tier. Choose based on expected query concurrency and complexity.

## Warehouse types

- **CLASSIC** — traditional SQL warehouse
- **PRO** (default) — enhanced with additional features (query history, result caching, parameter support)

The `enable_serverless_compute` variable controls whether serverless compute infrastructure is used behind the warehouse.

## Auto-scaling

Configure `min_num_clusters` and `max_num_clusters` to enable auto-scaling. The warehouse will scale between these bounds based on query load. Set both to 1 to disable auto-scaling.

## Spot instance policy

- **COST_OPTIMIZED** (default) — prefer spot instances for cost savings
- **RELIABILITY_OPTIMIZED** — prefer on-demand instances for stability
- **POLICY_UNSPECIFIED** — use workspace default

## Permissions

The `permissions` variable is a map of principal (user email, group name, or service principal application ID) to permission level:

```hcl
permissions = {
  "user@example.com"                              = "CAN_USE"
  "data-analysts"                                 = "CAN_USE"
  "12345678-1234-1234-1234-123456789012"         = "CAN_MANAGE"
  "admin-group"                                   = "IS_OWNER"
}
```

Valid permission levels: `CAN_USE`, `CAN_MANAGE`, `CAN_MONITOR`, `IS_OWNER`.

The module infers principal type from the format:
- **Service principal**: UUID format (e.g., `12345678-1234-1234-1234-123456789012`)
- **User**: contains `@` (e.g., `user@example.com`)
- **Group**: everything else (e.g., `data-analysts`)

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.50 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.workspace"></a> [databricks.workspace](#provider\_databricks.workspace) | 1.117.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_permissions.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/permissions) | resource |
| [databricks_sql_endpoint.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/sql_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_auto_stop_mins"></a> [auto\_stop\_mins](#input\_auto\_stop\_mins) | Time in minutes after which the warehouse will stop automatically if idle. Set to 0 to disable auto-stop. | `number` | `10` | no |
| <a name="input_channel"></a> [channel](#input\_channel) | Warehouse release channel. CURRENT for stable releases, PREVIEW for preview features. Valid values: CURRENT, PREVIEW. | `string` | `"CURRENT"` | no |
| <a name="input_cluster_size"></a> [cluster\_size](#input\_cluster\_size) | Size of the warehouse cluster. Valid values: 2X-Small, X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large. | `string` | n/a | yes |
| <a name="input_enable_photon"></a> [enable\_photon](#input\_enable\_photon) | Enable Photon acceleration. Requires Premium tier or higher. | `bool` | `true` | no |
| <a name="input_enable_serverless_compute"></a> [enable\_serverless\_compute](#input\_enable\_serverless\_compute) | Enable serverless compute for the warehouse. When true, warehouse uses serverless infrastructure. | `bool` | `false` | no |
| <a name="input_max_num_clusters"></a> [max\_num\_clusters](#input\_max\_num\_clusters) | Maximum number of warehouse clusters for auto-scaling. Must be >= min\_num\_clusters. | `number` | `1` | no |
| <a name="input_min_num_clusters"></a> [min\_num\_clusters](#input\_min\_num\_clusters) | Minimum number of warehouse clusters. Must be >= 1. | `number` | `1` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the SQL warehouse. Must be unique within the workspace. | `string` | n/a | yes |
| <a name="input_permissions"></a> [permissions](#input\_permissions) | Map of principal (user email, group name, or service principal application ID) to permission level. Valid permission levels: CAN\_USE, CAN\_MANAGE, CAN\_MONITOR, IS\_OWNER. | `map(string)` | `{}` | no |
| <a name="input_spot_instance_policy"></a> [spot\_instance\_policy](#input\_spot\_instance\_policy) | Spot instance policy for cost optimization. Valid values: COST\_OPTIMIZED, RELIABILITY\_OPTIMIZED, POLICY\_UNSPECIFIED. | `string` | `"COST_OPTIMIZED"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Custom tags to apply to the warehouse. | `map(string)` | `{}` | no |
| <a name="input_warehouse_type"></a> [warehouse\_type](#input\_warehouse\_type) | Type of the warehouse. Valid values: CLASSIC, PRO. | `string` | `"PRO"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_data_source_id"></a> [data\_source\_id](#output\_data\_source\_id) | The data source ID for the warehouse. Use this ID when creating SQL queries, dashboards, or alerts via the Databricks SQL API. |
| <a name="output_jdbc_url"></a> [jdbc\_url](#output\_jdbc\_url) | JDBC connection URL for the SQL warehouse. Use this to connect external tools via JDBC. |
| <a name="output_odbc_params"></a> [odbc\_params](#output\_odbc\_params) | ODBC connection parameters as a structured object. Contains host, path, protocol, and port for ODBC connections. |
| <a name="output_warehouse_id"></a> [warehouse\_id](#output\_warehouse\_id) | The ID of the SQL warehouse. Use this to reference the warehouse in queries, dashboards, and alerts. |
| <a name="output_warehouse_name"></a> [warehouse\_name](#output\_warehouse\_name) | The name of the SQL warehouse. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid cluster sizes are accepted
- Invalid cluster sizes are rejected
- Valid warehouse types are accepted
- Invalid warehouse types are rejected
- Valid spot policies are accepted
- Invalid spot policies are rejected
- Valid channels are accepted
- Invalid channels are rejected
- max_num_clusters < min_num_clusters is rejected via precondition
- Permission level validation
- Warehouse resource planned with expected attributes

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks workspace) verifies actual warehouse creation and permissions grants. It is credential-gated and is added when the test environment is wired (per DATABRICKS_RULES.md Rule 4.1).
