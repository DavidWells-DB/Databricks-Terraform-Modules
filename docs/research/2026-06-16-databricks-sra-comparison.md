# Gap Analysis: Our Modules vs. terraform-databricks-sra

**Date:** 2026-06-16
**Comparison:** 46 modules (ours) vs. `databricks/terraform-databricks-sra` (Security Reference Architecture)

---

## Structural comparison

The SRA is a **hardened reference deployment**, not a module library. Its "modules" are purpose-built for the SRA's specific security posture — full PrivateLink, CMK everywhere, compliance profile enabled, legacy features disabled. It has 23 modules across AWS (13), Azure (6), GCP (4).

Our modules are **primitives** designed for composition into any posture (quickstart through production-locked-down). The SRA's modules are more opinionated — they assume a specific security stance.

---

## (A) Coverage gaps — things in the SRA we DON'T have

### 1. Restrictive root bucket policy (post-workspace)
**SRA:** `aws/databricks_workspace/restrictive_root_bucket` — applies a least-privilege S3 policy to the workspace root bucket AFTER workspace creation. Scopes write access to specific workspace ID paths, enforces principal tag conditions, requires SSL.

**Our gap:** Our `aws-account-workspace-storage` creates the bucket with the Databricks-generated policy (via `databricks_aws_bucket_policy` data source). We don't have a post-workspace module that tightens the policy further with workspace-ID-scoped paths.

**Recommendation:** Add `aws-workspace-restrictive-root-bucket` module. This is a real workspace-layer primitive — the abstraction is "harden the root bucket policy after workspace creation when the workspace ID is known." It's security-critical and not achievable at workspace-creation time (workspace ID isn't known yet).

### 2. Account-level network policy (restrictive egress)
**SRA:** `aws/databricks_account/network_policy` — creates `databricks_account_network_policy` with `RESTRICTED_ACCESS` mode.

**Our gap:** Our `azure-account-network-connectivity-config` creates an optional `databricks_account_network_policy`, but our `aws-account-network-connectivity-config` does NOT. The NCC and network policy are separate concerns; our AWS NCC module only creates the NCC itself.

**Recommendation:** Add `dbx-account-network-policy` module (cloud-agnostic — the `databricks_account_network_policy` resource is provider-level, not cloud-specific). This is a legitimate missing primitive.

### 3. Classic cluster with security hardening
**SRA:** `aws/databricks_workspace/classic_cluster` — creates a cluster with `data_security_mode = "USER_ISOLATION"`, compliance-mode node type selection, and security tags.

**Our gap:** We have no cluster module. Clusters are workspace-level resources, and a `dbx-workspace-cluster` module that creates a hardened cluster (with security mode, policy binding, tags) is a legitimate primitive.

**Recommendation:** Consider `dbx-workspace-cluster` module. However — clusters are highly variable (job clusters, interactive, ML clusters all differ). The abstraction may be too broad. The SRA's module is narrow (one specific hardened cluster). This might be better as a blueprint-layer concern (cluster definitions are operational, not infrastructure). **Defer decision.**

### 4. Security Analysis Tool (SAT) deployment
**SRA:** `security_analysis_tool` module — deploys Databricks SAT with secrets and external module reference.

**Our gap:** We have nothing for SAT.

**Recommendation:** Skip. SAT is a third-party tool deployment (external git module reference), not an infrastructure primitive. It's also being superseded by built-in security features. Not a module-layer concern.

### 5. Isolated catalog with per-catalog KMS (AWS)
**SRA:** `aws/databricks_workspace/unity_catalog_catalog_creation` — creates a catalog with its OWN KMS key, its OWN S3 bucket, its OWN IAM role, its OWN storage credential, all in isolation mode.

**Our gap:** Our `dbx-uc-catalog` creates catalogs but doesn't create per-catalog cloud infrastructure (KMS, S3, IAM). Our UC storage credential modules are separate from catalog creation.

**Assessment:** The SRA's pattern is a **composition** (catalog + cloud storage + encryption + credential all together). Our primitives cover the same resources separately. Whether to combine them into a single "isolated catalog with backing infrastructure" module depends on whether that abstraction is reusable.

**Recommendation:** This is a blueprint-layer composition ("provision an isolated catalog end-to-end on AWS"), not a new primitive. Our modules already cover all the pieces. No new module needed.

### 6. Azure hub module (firewall + Key Vault + NCC + network policy + UC setup combined)
**SRA:** `azure/hub` — creates the entire hub infrastructure in one module.

**Assessment:** This is a composition/blueprint. Our primitives cover each piece separately. No gap.

---

## (B) Things the SRA does BETTER

### 1. Post-creation bucket policy hardening
The SRA's `restrictive_root_bucket` module is genuinely more secure than our approach. Our module uses the Databricks-generated policy (broad), while the SRA tightens it after workspace creation to scope writes to specific paths (`ephemeral/{region}-prod/{workspace_id}/*`, `user/hive/warehouse/*`, etc.). This is a real security improvement.

**Key pattern to extract:**
- Scope S3 write to: `ephemeral/`, `user/hive/warehouse/`, `FileStore/`, and workspace-specific prefixes
- Enforce `DatabricksAccountId` principal tag condition
- Deny non-HTTPS
- GovCloud: compute correct Databricks account ID per shard

### 2. GovCloud shard-aware Databricks account IDs in security policies
The SRA computes `local.databricks_account_id` per gov shard (same pattern we use) but ALSO uses it in S3 bucket policies and KMS policies as principal conditions. Our modules create the basic policies via Databricks data sources (`databricks_aws_bucket_policy`) but don't add the workspace-ID-scoped restrictions.

### 3. Isolation mode on storage credentials and catalogs
The SRA explicitly sets `isolation_mode = "ISOLATION_MODE_ISOLATED"` on storage credentials and catalogs. Our `dbx-uc-catalog` module supports an `isolation_mode` input, but our `aws-uc-storage-credential` may not expose it.

**Action:** Verify our UC storage credential modules expose `isolation_mode` as an input.

### 4. 60-second wait for IAM propagation before external locations
The SRA uses a 60s `time_sleep` before creating external locations (vs. our 30s for other IAM operations). External location creation is more sensitive to IAM propagation than credential registration.

**Action:** Verify our test coverage exercises the external location creation timing. May need to adjust `time_sleep` in `dbx-uc-external-location` if it depends on a freshly-created IAM role.

### 5. Workspace configuration hardening (GCP-specific)
The SRA's GCP `workspace_deployment` applies: IP access lists, verbose audit logs, token lifetime limits (90 days), DBFS browser disabled. These are workspace configurations beyond what our `dbx-workspace-compliance-settings` covers.

**Assessment:** Our `dbx-workspace-compliance-settings` covers the compliance profile + legacy disablement. Token lifetime, audit log level, and DBFS browser toggle are separate workspace conf settings. These could be additional inputs on our compliance module or a separate module.

**Action:** Verify whether `databricks_workspace_conf` settings (token lifetime, audit verbosity, DBFS browser) are covered by any of our workspace modules.

### 6. Testing: mock plan tests for GovCloud
The SRA has separate `mock_plan_gov.tftest.hcl` test files with GovCloud-specific mock data. Our modules exercise GovCloud branching in our standard plan tests (which is equivalent), but the SRA's pattern of separate test files per shard is more explicit.

**Assessment:** Our approach (multiple `run` blocks in one test file, each with different `databricks_gov_shard` values) achieves the same coverage more concisely. No action needed.

---

## (C) Value to extract

### 1. Restrictive S3 bucket policy template
The SRA's `restrictive_root_bucket` policy is the gold-standard for post-creation bucket hardening. Key elements:
- Read access: `GetObject`, `GetObjectVersion`, `ListBucket`, `GetBucketLocation`
- Write access scoped to workspace paths: `ephemeral/{region}-prod/{workspace_id}/*`, `user/hive/warehouse/*`, `FileStore/*`
- Principal tag condition: `aws:PrincipalTag/DatabricksAccountId` must match
- SSL enforcement: deny non-HTTPS
- GovCloud support: shard-aware account ID computation

Use this as the source pattern for our `aws-workspace-restrictive-root-bucket` module.

### 2. Azure compliance standards via `azapi_update_resource`
The SRA's Azure workspace module uses `azapi_update_resource` to set compliance standards that `azurerm_databricks_workspace` doesn't support natively. Our `azure-account-workspace` module already does this (Rule 3.2 Databricks). Confirmed: we already extracted this pattern.

### 3. Network policy as a standalone resource
The `databricks_account_network_policy` resource with `RESTRICTED_ACCESS` mode is a simple but important primitive we're missing. One resource, one module, clear abstraction: "the account-level network egress policy."

### 4. Azure naming module usage
The SRA uses `Azure/naming/azurerm` for consistent Azure resource naming. This is a community module pattern worth considering for our Azure modules' examples (not the modules themselves, since modules shouldn't impose naming on callers).

---

## Summary of gaps to address

| # | Item | Type | Priority |
|---|---|---|---|
| 1 | `aws-workspace-restrictive-root-bucket` | New module — post-creation bucket hardening | High (security) |
| 2 | `dbx-account-network-policy` | New module — account-level egress policy | Medium |
| 3 | Verify `isolation_mode` input on UC storage credential modules | Verification | Low |
| 4 | Verify workspace conf settings coverage (token lifetime, audit, DBFS browser) | Verification | Low |
| 5 | Verify `time_sleep` duration for external location IAM | Verification | Low |

## Items confirmed NOT gaps
- SAT deployment — third-party tool, being superseded
- Hub module (Azure) — composition/blueprint, not primitive
- Isolated catalog end-to-end — composition of our existing primitives
- Classic cluster module — too variable; defer to blueprint layer
- Azure `azapi_update_resource` workaround — already in our `azure-account-workspace`
- GovCloud shard handling — already in our modules via `databricks_gov_shard`

## Things the SRA does that are opinionated (not gaps, design differences)
- Forces PrivateLink on all workspaces (we make it optional via composition)
- Forces CMK on all resources (we expose `kms_key_arn` as optional)
- Disables all legacy features unconditionally (we expose as inputs)
- Combines cloud + Databricks + workspace operations in single modules (we split per Rule 1.1)
- Uses `count` for conditional creation (we avoid feature flags per Rule 2.7)
