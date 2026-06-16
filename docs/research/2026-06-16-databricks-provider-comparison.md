# Gap Analysis: Our Modules vs. terraform-provider-databricks Resource Catalog

**Date:** 2026-06-16
**Comparison:** 46 modules (ours) vs. all 154 resources in the Databricks Terraform provider

---

## Approach

Not every provider resource warrants a module. Per Rule 1.1, a module is justified when resources form a meaningful abstraction. Single-resource wrappers are anti-patterns (Rule 1.2). This analysis categorizes ALL 154 resources into: covered by our modules, correctly not wrapped, or legitimate gaps.

---

## Resources COVERED by our 46 modules

### Account / MWS resources (all covered)
| Resource | Our module |
|---|---|
| `mws_credentials` | `aws-account-workspace-credentials` |
| `mws_customer_managed_keys` | `aws-account-encryption-keys` |
| `mws_log_delivery` | `aws-account-log-delivery` |
| `mws_ncc_binding` | `dbx-workspace-network-serverless` |
| `mws_ncc_private_endpoint_rule` | `dbx-workspace-network-serverless` |
| `mws_network_connectivity_config` | `aws/azure/gcp-account-network-connectivity-config` |
| `mws_networks` | `aws/gcp-account-network-vpc` |
| `mws_permission_assignment` | `dbx-workspace-identity` |
| `mws_private_access_settings` | `aws-account-network-privatelink-endpoints`, `gcp-account-network-psc-endpoints` |
| `mws_storage_configurations` | `aws-account-workspace-storage`, `gcp-account-workspace-storage` |
| `mws_vpc_endpoint` | `aws-account-network-privatelink-endpoints`, `gcp-account-network-psc-endpoints` |
| `mws_workspaces` | `aws/gcp-account-workspace`, `aws/gcp-account-workspace-serverless` |
| `account_network_policy` | `azure-account-network-connectivity-config` (partial — missing standalone module) |

### Unity Catalog resources (covered)
| Resource | Our module |
|---|---|
| `metastore` | `dbx-uc-metastore` |
| `metastore_assignment` | `dbx-uc-metastore-assignment` |
| `metastore_data_access` | `dbx-uc-metastore` |
| `storage_credential` | `aws/azure/gcp-uc-storage-credential` |
| `external_location` | `dbx-uc-external-location` |
| `catalog` | `dbx-uc-catalog` |
| `schema` | `dbx-uc-schema` |
| `grants` | `dbx-uc-catalog`, `dbx-uc-schema`, `dbx-uc-external-location` |
| `default_namespace_setting` | `dbx-uc-metastore-assignment` |

### Workspace resources (covered)
| Resource | Our module |
|---|---|
| `cluster_policy` | `dbx-workspace-cluster-policies` |
| `permissions` | `dbx-workspace-cluster-policies` |
| `ip_access_list` | `dbx-workspace-ip-access-list` |
| `workspace_conf` | `dbx-workspace-ip-access-list` |
| `secret_scope` | `dbx-workspace-secret-scope` |
| `compliance_security_profile_setting` | `dbx-workspace-compliance-settings` |
| `enhanced_security_monitoring_setting` | `dbx-workspace-compliance-settings` |
| `automatic_cluster_update_setting` | `dbx-workspace-compliance-settings` |
| `disable_legacy_access_setting` | `dbx-workspace-compliance-settings` |
| `disable_legacy_dbfs_setting` | `dbx-workspace-compliance-settings` |
| `workspace_network_option` | `dbx-workspace-network-serverless` |

---

## Resources CORRECTLY NOT wrapped (no module needed)

These are resources that don't form meaningful multi-resource abstractions, are operational/application-level concerns, or are too variable for a reusable module.

### Application-level (DAB/workflow territory, not infrastructure)
- `job`, `pipeline`, `notebook`, `repo`, `workspace_file`, `file`, `dbfs_file`, `directory`
- `mlflow_experiment`, `mlflow_model`, `mlflow_webhook`, `registered_model`
- `model_serving`, `model_serving_provisioned_throughput`
- `sql_query`, `sql_visualization`, `sql_widget`, `sql_dashboard`, `sql_alert`, `dashboard`
- `alert`, `alert_v2`, `notification_destination`
- `vector_search_endpoint`, `vector_search_index`
- `ai_search_endpoint`, `ai_search_index`
- `online_table`, `online_store`
- `feature_engineering_feature`, `feature_engineering_kafka_config`, `feature_engineering_materialized_feature`
- `library`, `global_init_script`
- `mount` (legacy, deprecated pattern)

### Identity resources (managed by IdP, not modules)
- `user`, `group`, `group_member`, `group_role`, `group_instance_profile`
- `service_principal`, `service_principal_role`, `service_principal_secret`
- `service_principal_federation_policy`, `account_federation_policy`
- `entitlements`, `permission_assignment`
- `obo_token`, `token`, `git_credential`

### Single-resource settings (thin wrappers, Rule 1.2)
- `workspace_setting_v2`, `account_setting_v2`, `account_setting_user_preference_v2`
- `restrict_workspace_admins_setting`
- `disable_legacy_features_setting`
- `aibi_dashboard_embedding_access_policy_setting`
- `aibi_dashboard_embedding_approved_domains_setting`

### Data sharing (Delta Sharing — separate domain)
- `share`, `recipient`, `provider`

### Instance management (operational, cluster-level)
- `cluster`, `instance_pool`, `instance_profile`, `user_instance_profile`

### Tagging / metadata
- `entity_tag_assignment`, `workspace_entity_tag_assignment`, `tag_policy`

### Legacy / deprecated
- `sql_permissions` (replaced by `grants`)
- `sql_global_config`
- `quality_monitor` (replaced by `quality_monitor_v2`)
- `lakehouse_monitor` (alias for quality_monitor)

### Misc single-purpose
- `connection` (external connections like Snowflake/MySQL)
- `volume` (UC volume — typically part of catalog/schema lifecycle)
- `sql_table` (DDL — not infrastructure)
- `workspace_binding`, `catalog_workspace_binding` (covered inline by UC modules)
- `artifact_allowlist`
- `custom_app_integration`
- `system_schema`
- `budget`, `budget_policy`
- `secret`, `secret_acl` (values — not structure; per our Rule 3.2)
- `access_control_rule_set`
- `rfa_access_request_destinations`

---

## LEGITIMATE GAPS — resources that warrant new modules

### 1. SQL Warehouse / Endpoint
**Resource:** `sql_endpoint` (also aliased as `sql_warehouse` in some docs)

**Why it's a module:** A SQL warehouse involves sizing config, spot policy, channel selection, warehouse type, auto-stop, tags, AND permissions — enough configuration to be a meaningful abstraction. "Give this workspace a SQL warehouse with governance" is a real primitive.

**Already identified in:** terraform-databricks-examples comparison (gap #4).

**Recommendation:** `dbx-workspace-sql-warehouse` — High priority.

### 2. Databricks Apps
**Resources:** `app`, `app_space`, `apps_settings_custom_template`

**Why it's a module:** An App deployment involves the app definition, the app space (compute), and optionally a custom template. These three resources form one indivisible function: "deploy an app."

**Assessment:** Apps are relatively new (v1.107+). Whether they're infrastructure-module territory or DAB territory is debatable. They use workspace-level API and require compute resources — feels more infrastructure than application code.

**Recommendation:** Consider `dbx-workspace-app` — Low priority. Evaluate once Apps are more mature.

### 3. Postgres / Lakebase
**Resources (7):** `postgres_project`, `postgres_endpoint`, `postgres_branch`, `postgres_database`, `postgres_role`, `postgres_catalog`, `postgres_synced_table`

**Why it's a module:** Lakebase (PostgreSQL federation) is a new Databricks feature (Jan-Apr 2026). A project + endpoint + database + roles form a meaningful abstraction: "give this workspace a Lakebase instance."

**Assessment:** Very new (v1.102-v1.113, last 6 months). Resources may still be evolving. But the abstraction is clear and the resource set is cohesive.

**Recommendation:** `dbx-workspace-lakebase` — Medium priority. Wait for GA stabilization, then build.

### 4. Disaster Recovery
**Resources (2):** `disaster_recovery_failover_group`, `disaster_recovery_stable_url`

**Why it's a module:** DR failover groups + stable URLs form one abstraction: "this workspace has disaster recovery configured." The two resources are 1:1 coupled.

**Assessment:** Brand new (v1.114.0, Apr 2026). May still be experimental.

**Recommendation:** `dbx-account-disaster-recovery` — Low priority. Wait for maturity.

### 5. Data Quality Monitor v2
**Resources:** `quality_monitor_v2`, `data_quality_monitor`, `data_quality_refresh`

**Why it's a module:** Data quality monitoring involves monitor definition + refresh schedule + metric tables. "Monitor this table's quality" is a workspace-level primitive.

**Assessment:** Operational/data-engineering concern, not infrastructure. Closer to DAB territory. But it creates persistent resources that need lifecycle management.

**Recommendation:** Defer. This sits between infrastructure and application. Not clearly a module-layer concern.

### 6. Knowledge Assistant
**Resources (2):** `knowledge_assistant`, `knowledge_assistant_knowledge_source`

**Why it's a module:** An assistant + its knowledge sources form one abstraction.

**Assessment:** Very new (v1.111.0, Mar 2026). AI feature, likely to evolve rapidly. More application than infrastructure.

**Recommendation:** Skip for now. Application-layer concern.

---

## NEW resources (last 6 months) — evaluation

| Resource | Version | Assessment |
|---|---|---|
| `postgres_project` | v1.102 (Jan 2026) | Module candidate (`dbx-workspace-lakebase`) |
| `postgres_endpoint` | v1.102 | Part of Lakebase module |
| `postgres_branch` | v1.102 | Part of Lakebase module |
| `postgres_database` | v1.111 (Mar 2026) | Part of Lakebase module |
| `postgres_role` | v1.112 (Mar 2026) | Part of Lakebase module |
| `postgres_catalog` | v1.113 (Apr 2026) | Part of Lakebase module |
| `postgres_synced_table` | v1.113 | Part of Lakebase module |
| `knowledge_assistant` | v1.111 | Skip — application layer |
| `knowledge_assistant_knowledge_source` | v1.111 | Skip — application layer |
| `environments_default_workspace_base_environment` | v1.113 | Skip — single setting |
| `environments_workspace_base_environment` | v1.113 | Skip — single setting |
| `disaster_recovery_failover_group` | v1.114 (Apr 2026) | Module candidate (low priority) |
| `disaster_recovery_stable_url` | v1.114 | Part of DR module |
| `supervisor_agent` | v1.114 | Skip — application layer |
| `supervisor_agent_tool` | v1.114 | Skip — application layer |
| `secret_uc` | v1.114 | Skip — UC secrets, single resource |
| `data_classification_catalog_config` | v1.111 | Skip — single setting |
| `app_space` | v1.107/v1.111 | Consider with `dbx-workspace-app` |

---

## Summary — consolidated gap list (all three comparisons + provider)

| # | Module | Source | Priority |
|---|---|---|---|
| 1 | `dbx-workspace-sql-warehouse` | terraform-databricks-examples + provider | **High** |
| 2 | `aws-workspace-restrictive-root-bucket` | SRA | **High (security)** |
| 3 | `dbx-account-network-policy` | SRA + provider | Medium |
| 4 | `dbx-workspace-team` | terraform-databricks-examples | Medium |
| 5 | `aws-account-network-serverless-privatelink` | terraform-databricks-examples | Medium |
| 6 | `gcp-account-vpc-service-controls` | Monorepo | Medium |
| 7 | `dbx-workspace-lakebase` | Provider (new resources) | Medium (wait for GA) |
| 8 | `dbx-workspace-app` | Provider (new resources) | Low |
| 9 | `dbx-account-disaster-recovery` | Provider (new resources) | Low (wait for maturity) |

## Verification items (from all comparisons)
- Verify `dbx-workspace-cluster-policies` supports `policy_family_id` input
- Verify UC storage credential modules expose `isolation_mode` input
- Verify workspace conf settings coverage (token lifetime, audit, DBFS browser)
- Verify PrivateLink module covers 16+ AWS regions
- Verify `time_sleep` duration for external location IAM (SRA uses 60s)
- Add `force_destroy` input to storage modules

---

## Provider version implications

Our modules pin `databricks >= 1.50`. The provider is now at v1.114+. Resources we use are stable at 1.50, but if we add modules for newer resources:
- Lakebase: requires `>= 1.102`
- DR: requires `>= 1.114`
- Apps: requires `>= 1.107`

These would be documented per Databricks Rule 6.1 (version pin with comment naming the feature).
