# Gap Analysis: Our Modules vs. terraform-databricks-examples

**Date:** 2026-06-16
**Comparison:** 46 modules (ours) vs. `databricks/terraform-databricks-examples` repo

---

## Key structural difference

The public repo's "modules" are **mostly compositions** (blueprints), not primitives. For example:
- `aws-workspace-basic` creates VPC + S3 + IAM role + workspace — all in one module
- `adb-lakehouse` creates VNet + NSG + NAT + workspace + Data Factory + Key Vault + Storage — all in one module
- `aws-exfiltration-protection` creates hub/spoke VPCs + Transit Gateway + Network Firewall + workspace

Our modules are **primitives** — one module per abstraction. The public repo's modules are what we'd call compositions/blueprints in our taxonomy. They're not directly comparable at the module level.

The public repo has only **3 truly reusable primitive modules**:
1. `databricks-department-clusters` — workspace-level team provisioning (clusters + policies + SQL endpoints)
2. `cluster-policy-from-policy-family` — cluster policy from policy family
3. `uc-idf-assignment` — UC metastore + identity federation assignment

---

## (A) Coverage gaps — things in the public repo we DON'T have

### 1. Team/department provisioning module
**Public:** `databricks-department-clusters` — creates groups, shared cluster, SQL endpoint, cluster policy with permissions, all scoped to a department/team.

**Our gap:** We have `dbx-workspace-cluster-policies` (policies) and `dbx-workspace-identity` (assignments) separately, but no module that composes: "provision a team in this workspace with their cluster, endpoint, and policies." This is a legitimate workspace-level primitive we're missing — the abstraction is "a team's compute footprint in a workspace."

**Recommendation:** Add `dbx-workspace-team` module.

### 2. Cluster policy from policy family
**Public:** `cluster-policy-from-policy-family` — creates a cluster policy using a `policy_family_id` + `policy_family_definition_overrides` instead of raw JSON.

**Our gap:** Our `dbx-workspace-cluster-policies` supports both raw `definition` and `policy_family_id` + overrides. If it already handles both paths, no gap. Need to verify our implementation supports the `policy_family_id` input path.

**Action:** Verify `dbx-workspace-cluster-policies` variables.tf supports `policy_family_id` + `policy_family_definition_overrides` in the `policies` map.

### 3. UC identity federation assignment
**Public:** `uc-idf-assignment` — assigns UC metastore, then grants workspace-level permissions to groups and service principals in one shot.

**Our coverage:** We have `dbx-uc-metastore-assignment` (assigns metastore) and `dbx-workspace-identity` (assigns principals). The public repo's module combines both into one operation. This is a composition, not a new primitive — we cover the same resources via two separate modules.

**Recommendation:** No new module. Our separation is by design (two distinct abstractions per Rule 1.1).

### 4. SQL endpoint / SQL warehouse module
**Public:** `databricks-department-clusters` creates `databricks_sql_endpoint` as part of team provisioning.

**Our gap:** We have NO standalone SQL warehouse module. A `dbx-workspace-sql-warehouse` module that creates a `databricks_sql_endpoint` with sizing, spot policy, channel, and permissions is a legitimate missing primitive.

**Recommendation:** Add `dbx-workspace-sql-warehouse` module.

### 5. AWS serverless-to-cloud-service PrivateLink (NLB pattern)
**Public:** `aws-serverless-privatelink-to-cloud-service` — creates NLB + VPC endpoint service + VPC endpoint + authorization + NCC PE rule for serverless compute reaching customer services (RDS, Redshift, etc.) over PrivateLink.

**Our gap:** Our `dbx-workspace-network-serverless` creates NCC bindings and PE rules, but doesn't create the NLB/VPC endpoint service on the customer VPC side. The public module handles the customer-side infrastructure that makes the PrivateLink connection work end-to-end.

**Recommendation:** Add `aws-account-network-serverless-privatelink` module.

### 6. Overwatch/monitoring modules (Azure-specific)
**Public:** 4 Overwatch modules (`adb-overwatch-regional-config`, `adb-overwatch-mws-config`, `adb-overwatch-main-ws`, `adb-overwatch-ws-to-monitor`).

**Our gap:** We have nothing for Overwatch/monitoring.

**Recommendation:** Skip. Overwatch is being deprecated in favor of system tables.

### 7. DBSQL dashboard/analysis module
**Public:** `dbsql-nyc-taxi-trip-analysis` — deploys pre-built SQL queries + dashboard.

**Our gap:** We have nothing for deploying SQL assets.

**Recommendation:** Skip. Demo artifact, not a reusable infrastructure module. Dashboard deployment is a DAB concern.

---

## (B) Things the public repo does BETTER

### 1. Policy family support in cluster policies
The public `cluster-policy-from-policy-family` module is purpose-built for the newer policy-family API pattern. Ours may try to do both (raw JSON + policy family) in one `policies` map, which adds complexity. The public repo's dedicated module is simpler and easier to understand.

**Check:** Read our `dbx-workspace-cluster-policies/variables.tf` to see how `policy_family_id` is handled.

### 2. End-to-end example compositions
The public repo's compositions (`aws-workspace-basic`, `adb-lakehouse`, `adb-exfiltration-protection`, etc.) are complete working deployments showing how primitives wire together. We deliberately don't have these in our module catalog (they belong in blueprints), but they're valuable as references for HOW compositions should look.

**Action for later:** When building blueprints, use public repo compositions as reference patterns for wiring.

### 3. Test VM in private link examples
The public Azure PL module (`adb-with-private-link-standard`) includes a test VM to verify connectivity. This is a clever testing pattern — a "canary" resource that validates the network actually works.

**Applicable to:** Our integration tests for `azure-account-network-private-endpoints` could use this pattern.

---

## (C) Value to extract

### 1. NLB pattern for serverless PrivateLink
The `aws-serverless-privatelink-to-cloud-service` module solves a real customer problem (how to reach RDS/Redshift from serverless compute privately). The specific resources (NLB, target group, VPC endpoint service, endpoint authorization, NCC PE rule) are well-documented there. Use as the source pattern for our `aws-account-network-serverless-privatelink` module.

### 2. Azure data storage + NCC pattern
`adb-data-storage-vnet-ncc-private-endpoint` shows the full wiring for connecting a workspace to storage via NCC private endpoints on Azure. Not a new module — but useful reference for blueprint-layer compositions on Azure.

### 3. GCP PSC exfiltration protection pattern
`gcp-with-psc-exfiltration-protection` shows hub-spoke with PSC and firewall rules on GCP. Blueprint-level reference, not a module.

---

## Summary of gaps to address

| # | Module to add | Why | Priority |
|---|---|---|---|
| 1 | `dbx-workspace-sql-warehouse` | Real workspace-layer primitive; no coverage currently | High |
| 2 | `dbx-workspace-team` | Team provisioning abstraction (group + cluster + SQL endpoint + policy) | Medium |
| 3 | `aws-account-network-serverless-privatelink` | NLB + endpoint service for serverless-to-customer-service PrivateLink | Medium |

## Items confirmed NOT gaps
- Overwatch modules — being deprecated
- DBSQL dashboard module — demo artifact, not infrastructure
- UC IDF assignment — already covered by our two separate modules
- End-to-end compositions — belong in blueprints, not modules
