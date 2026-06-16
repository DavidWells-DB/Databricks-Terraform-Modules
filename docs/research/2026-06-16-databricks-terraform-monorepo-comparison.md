# Gap Analysis: Our Modules vs. Databricks-Terraform-Monorepo

**Date:** 2026-06-16
**Comparison:** 46 modules (ours) vs. `DavidWells-DB/Databricks-Terraform-Monorepo`

---

## Structural comparison

The monorepo uses a **3-tier composition pattern**:
- **Tier 1 — Components** (atomic): `root-storage`, `cross-account-role`, `cmek-keys`, `storage-config`, `credential-config`, `network-config`, `key-config`
- **Tier 2 — Core Modules** (feature-oriented): `network-foundation`, `base-workspace`, `account-uc-setup`, `network-privatelink`
- **Tier 3 — Stacks** (complete deployments): `workspace-stack`

Our modules map closest to a **mix of their Tier 1 and Tier 2**. Our "primitives" are sometimes more granular (we split `network-foundation` into vpc + egress + endpoints + firewall + TGW + peering), sometimes at the same grain (workspace-credentials ≈ their cross-account-role + credential-config combined per Rule 1.4).

**Total modules in monorepo:** 30 (11 AWS, 8 Azure, 8 GCP, 2 shared, plus stacks)

---

## (A) Coverage gaps — things in the monorepo we DON'T have

### 1. VPC Service Controls (GCP)
**Monorepo:** `gcp/vpc-service-controls` — creates a VPC Service Control perimeter for security isolation.

**Our gap:** We have no module for GCP VPC Service Controls. This is a real GCP-side primitive — the abstraction is "the security perimeter that restricts data egress from a GCP project."

**Recommendation:** Add `gcp-account-vpc-service-controls` module. Legitimate primitive.

### 2. Account-level UC setup (combined metastore + storage + credential)
**Monorepo:** `{aws,azure,gcp}/account-uc-setup` — creates the metastore, its backing storage, and the storage credential all in one module.

**Our coverage:** We split these into separate modules:
- `{cloud}-uc-storage-credential` (cloud resource + credential)
- `dbx-uc-metastore` (metastore + data access)
- `{cloud}-account-workspace-storage` (backing storage)

**Assessment:** The monorepo's combined module is a **composition** of our primitives. Our split is by design (Rule 1.1 — each is a distinct abstraction). Not a gap; architectural choice.

### 3. Shared `workspace-uc-binding` module
**Monorepo:** `shared/workspace-uc-binding` — assigns metastore + optionally creates a workspace catalog + grants.

**Our coverage:** `dbx-uc-metastore-assignment` (metastore assignment) + `dbx-uc-catalog` (catalog creation) + grants built into each UC module.

**Assessment:** Same resources, different composition point. Not a gap.

### 4. Shared `network-serverless-security` with cloud branching
**Monorepo:** `shared/network-serverless-security` — single module that branches on `var.cloud_provider` to create cloud-specific NCC + PE rules.

**Our coverage:** `dbx-workspace-network-serverless` is already cloud-agnostic (NCC and PE rules are provider-level Databricks resources, not cloud-specific). Our module handles this cleanly without branching.

**Assessment:** No gap. Our approach is cleaner (no cloud branching inside a module).

---

## (B) Things the monorepo does BETTER

### 1. BYO (Bring-Your-Own) mode in network modules
**Monorepo:** `network-foundation` supports both CREATE and BYO modes via `existing_vpc_id`, `existing_private_subnet_ids`, etc. One module handles both paths.

**Our approach:** Per Rule 2.7, our modules always create — BYO is a root-composition concern (use data sources at the root). 

**Assessment:** The monorepo's BYO pattern is convenient for users but violates our Rule 2.7 (pure dependency inversion). We explicitly rejected this pattern. Not a thing to adopt — confirmed design divergence.

### 2. Regional PrivateLink service endpoint map
**Monorepo:** `aws/network-privatelink` hardcodes a complete map of 16+ AWS regions to their Databricks PrivateLink service names (workspace + relay endpoints per region).

**Our approach:** Our `aws-account-network-privatelink-endpoints` uses computed locals from `databricks_gov_shard` and `region` inputs, likely with the same hardcoded map.

**Action:** Verify our privatelink module has complete regional coverage (16+ regions). The monorepo's map is a good reference for ensuring we didn't miss regions.

### 3. Separate `storage-config`, `credential-config`, `network-config` atomic components
**Monorepo Tier 1** has tiny single-resource modules for `databricks_mws_storage_configurations`, `databricks_mws_credentials`, `databricks_mws_networks` individually.

**Our approach:** We pair cloud-side + Databricks-side per Rule 1.4 (e.g., S3 bucket + `databricks_mws_storage_configurations` together in `aws-account-workspace-storage`).

**Assessment:** The monorepo's approach is MORE granular than ours at Tier 1, then composes at Tier 2. Our pairing approach (Rule 1.4) is the better abstraction — "the storage Databricks uses" is one concept, not two. Their Tier 1 components are thin wrappers around single resources (exactly what Rule 1.2 says shouldn't be modules unless reused independently). Not a thing to adopt.

### 4. Feature flags (`create_*`, `enable_*`)
**Monorepo:** Uses `create_nat_gateway = true`, `create_vpc_endpoints = true`, `enable_privatelink = true` flags to conditionally create resources within a module.

**Our approach:** We don't toggle resources inside modules. Each primitive either creates its resources or doesn't exist. Composition is at the root.

**Assessment:** The monorepo's feature flags are convenient but create multi-responsibility modules (one module does 3 different things depending on flags). Our approach is simpler per-module and pushes composition to where it belongs. Confirmed design divergence.

### 5. `force_destroy` and `prevent_destroy` lifecycle inputs
**Monorepo:** Exposes lifecycle controls as inputs: `force_destroy` on S3 buckets, `prevent_destroy` as a flag.

**Our approach:** Not present in our modules.

**Action:** Consider adding `force_destroy` as an input on storage modules (`aws-account-workspace-storage`, `aws-account-log-delivery`, `gcp-account-workspace-storage`). This is a legitimate operational concern — without it, `terraform destroy` fails on non-empty buckets. It's a genuine input constraint, not a feature flag.

### 6. Provider version >= 1.84 (monorepo) vs. >= 1.50 (ours)
**Monorepo:** Requires `databricks >= 1.84`.

**Our approach:** `databricks >= 1.50`.

**Action:** Review whether our lower bound is too low. Per Databricks Rule 6.1, the lower bound should reflect the specific feature used. If the resources we use were stable at 1.50, our bound is correct. If newer provider versions fixed bugs in resources we depend on, we should bump. No action unless specific evidence surfaces.

---

## (C) Value to extract

### 1. Regional PrivateLink endpoint map
The monorepo's hardcoded map of 16+ regions → service attachment names is a valuable cross-reference for our `aws-account-network-privatelink-endpoints` module. Verify we have equivalent coverage.

### 2. GCP VPC Service Controls pattern
The monorepo's `gcp/vpc-service-controls` module is the source pattern for our proposed `gcp-account-vpc-service-controls`.

### 3. `force_destroy` on storage modules
A practical gap worth closing. When users run `terraform destroy` on a workspace, the S3/GCS/ADLS bucket may be non-empty (Databricks writes to it). Without `force_destroy = true`, destroy fails. This is a legitimate lifecycle input, not a feature flag.

---

## Summary of gaps to address

| # | Item | Type | Priority |
|---|---|---|---|
| 1 | `gcp-account-vpc-service-controls` | New module | Medium |
| 2 | `force_destroy` input on storage modules | Enhancement to existing modules | Low |
| 3 | Verify PrivateLink regional coverage (16+ regions) | Verification | Low |

## Items confirmed NOT gaps (design divergences we maintain)
- BYO mode inside modules — we use Rule 2.7 (pure dependency inversion); BYO is root-composition
- Feature flags (`create_*`, `enable_*`) — our modules are single-purpose; composition at root
- Separate atomic components for `databricks_mws_*` registrations — our Rule 1.4 pairing is better
- Combined `account-uc-setup` — our split is by design (separate abstractions)
- Shared cloud-branching modules — our modules are cloud-specific at account layer, cloud-agnostic only at workspace layer

## Things the monorepo does that we explicitly rejected
- BYO toggle pattern (Rule 2.7)
- Feature flags creating multi-responsibility modules
- Thin single-resource wrapper modules (Rule 1.2)
- Hardcoded Databricks AWS account ID without parameterization (their KMS policy hardcodes `414351767826`; we compute per gov_shard)
