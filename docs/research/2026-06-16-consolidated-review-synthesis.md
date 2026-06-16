# Consolidated Review Synthesis

**Date:** 2026-06-16
**Sources reviewed:** terraform-databricks-examples, Databricks-Terraform-Monorepo, terraform-databricks-sra, terraform-provider-databricks

---

## Filter applied

Each item below passed this test: "Does this solve a real problem or address a real use case that our current 46 modules cannot serve?" If the answer was "it's just how another repo did it" or "it's interesting but doesn't solve a problem we have," it was dropped.

---

## New modules worth building (6)

### High priority

**1. `dbx-workspace-sql-warehouse`**
- **Problem it solves:** SQL warehouses are a core workspace primitive. Every production workspace needs at least one. There's no way to provision "a governed SQL warehouse" today without writing raw resources at the root composition.
- **Resources:** `databricks_sql_endpoint` + `databricks_permissions`
- **Abstraction:** "Give this workspace a SQL warehouse with sizing, spot policy, channel, auto-stop, and access grants."
- **Source evidence:** Public examples repo uses this in `databricks-department-clusters`; provider has `sql_endpoint` as a mature resource.

**2. `aws-workspace-restrictive-root-bucket`**
- **Problem it solves:** After workspace creation, the DBFS root bucket has a broad Databricks-generated policy. Tightening it to scope writes to workspace-specific paths and enforce principal tag conditions is a real security hardening step that can't happen at creation time (workspace ID unknown).
- **Resources:** `aws_s3_bucket_policy` (replacement policy with workspace-ID-scoped paths)
- **Abstraction:** "Harden this workspace's root bucket to least-privilege after the workspace exists."
- **Source evidence:** SRA does this in `restrictive_root_bucket`; the policy template is well-defined and battle-tested.

### Medium priority

**3. `dbx-account-network-policy`**
- **Problem it solves:** Account-level egress restriction (`RESTRICTED_ACCESS` mode) is a single resource that's architecturally important for security posture. Our NCC modules create connectivity; this module restricts it. Complementary primitives.
- **Resources:** `databricks_account_network_policy`
- **Abstraction:** "Set the account-level network egress posture."
- **Source evidence:** SRA uses this; provider has the resource stable since v1.50+.

**4. `aws-account-network-serverless-privatelink`**
- **Problem it solves:** Databricks serverless compute reaching customer resources (RDS, Redshift, etc.) requires NLB + VPC endpoint service + authorization on the customer VPC side. Our `dbx-workspace-network-serverless` handles the Databricks side (NCC binding + PE rules) but NOT the customer-side infrastructure.
- **Resources:** `aws_lb` (NLB), `aws_lb_target_group`, `aws_vpc_endpoint_service`, `aws_vpc_endpoint_service_allowed_principal`, NCC PE rule
- **Abstraction:** "Make a customer resource reachable from Databricks serverless over PrivateLink."
- **Source evidence:** Public examples repo's `aws-serverless-privatelink-to-cloud-service` module solves this exact problem for real customers.

**5. `gcp-account-vpc-service-controls`**
- **Problem it solves:** GCP security perimeters restrict data egress at the project level. Without this, GCP workspaces lack an egress isolation primitive equivalent to AWS Network Firewall or Azure Firewall.
- **Resources:** `google_access_context_manager_service_perimeter`, related resources
- **Abstraction:** "Create a security perimeter for this GCP project."
- **Source evidence:** Monorepo has this module; GCP customers with data exfiltration requirements need it.

**6. `dbx-workspace-lakebase`**
- **Problem it solves:** Lakebase (PostgreSQL federation) is a new Databricks feature with 7 resources that form one cohesive abstraction. Customers deploying Lakebase need project + endpoint + database + roles composed together.
- **Resources:** `databricks_postgres_project`, `databricks_postgres_endpoint`, `databricks_postgres_database`, `databricks_postgres_role`
- **Abstraction:** "Give this workspace a Lakebase instance."
- **Source evidence:** Provider added 7 resources in Jan-Apr 2026. Feature is approaching GA. Cohesive resource set that always deploys together.
- **Caveat:** Wait for GA stabilization before building. Resources may still evolve.

---

## Enhancements to existing modules (3)

**1. `force_destroy` input on storage modules**
- **Problem:** `terraform destroy` fails on non-empty S3/GCS buckets without `force_destroy = true`. Users hit this in every teardown of a workspace.
- **Modules affected:** `aws-account-workspace-storage`, `aws-account-log-delivery`, `gcp-account-workspace-storage`
- **Change:** Add `force_destroy` variable (type bool, default false, described as "destroy bucket even if non-empty").
- **Source evidence:** Monorepo exposes this; practical problem every user hits.

**2. `isolation_mode` input on UC storage credential modules**
- **Problem:** Regulated customers need isolated catalogs. The SRA sets `isolation_mode = "ISOLATION_MODE_ISOLATED"` on storage credentials. If our UC credential modules don't expose this input, customers can't isolate without writing raw resources.
- **Modules affected:** `aws-uc-storage-credential`, `azure-uc-storage-credential`, `gcp-uc-storage-credential`
- **Change:** Add `isolation_mode` variable (type string, default null, validation for allowed values).
- **Source evidence:** SRA uses this explicitly; provider supports it.

**3. Verify PrivateLink regional coverage (16+ regions)**
- **Problem:** If our hardcoded service-attachment-name map is incomplete, customers in newer AWS regions can't deploy PrivateLink.
- **Module affected:** `aws-account-network-privatelink-endpoints`
- **Change:** Cross-reference our region map against the monorepo's 16-region map and Databricks docs. Add any missing regions.
- **Source evidence:** Monorepo has 16+ regions hardcoded; SRA references this map too.

---

## Patterns worth adopting (2)

**1. Test VM / canary pattern for network integration tests**
- **What:** The public examples repo's Azure Private Link module includes a test VM that validates connectivity through the PE by curling the workspace URL.
- **Value:** Proves the network actually works, not just that resources were created.
- **Where to apply:** Our integration tests for `azure-account-network-private-endpoints` and `aws-account-network-privatelink-endpoints`. Not a module change — a testing pattern for when we activate apply-command tests.

**2. 60s `time_sleep` for external location IAM propagation**
- **What:** The SRA uses 60s (not 30s) before creating external locations that depend on a freshly-created IAM role.
- **Value:** External locations are more sensitive to IAM propagation than credential registrations.
- **Where to apply:** If `dbx-uc-external-location` or its callers depend on freshly-created IAM roles, the `time_sleep` in the UC storage credential modules (or the external location module's examples) should be 60s, not 30s.
- **Action:** Check whether this timing matters for our module (it may already be fine if the role is created by a separate module that completes before external location is called).

---

## Deferred to blueprint/composition layer

- `dbx-workspace-team` — "provision a team" (group + cluster + SQL endpoint + policy). Real abstraction, but it's a composition of primitives. Belongs in the next stage when we build compositions.

---

## Items dropped (did not pass value test)

| Item | Source | Why dropped |
|---|---|---|
| BYO toggle pattern (`existing_vpc_id`) | Monorepo | Violates Rule 2.7; root-composition concern |
| Feature flags (`create_*`, `enable_*`) | Monorepo | Creates multi-responsibility modules; composition belongs at root |
| Thin single-resource wrapper modules | Monorepo | Rule 1.2 anti-pattern |
| Combined `account-uc-setup` | Monorepo, SRA | Composition of our existing primitives; not a new abstraction |
| Overwatch modules | Examples repo | Being deprecated in favor of system tables |
| DBSQL dashboard module | Examples repo | Demo artifact; DAB territory |
| UC IDF combined assignment | Examples repo | Already covered by our two separate modules |
| Classic cluster module | SRA | Too variable; defer to blueprint layer |
| SAT deployment | SRA | Third-party tool; being superseded |
| Hub module (Azure combined) | SRA | Composition/blueprint, not primitive |
| Knowledge Assistant module | Provider | Application-layer; too new |
| Supervisor Agent module | Provider | Application-layer; too new |
| Disaster Recovery module | Provider | Too new (Apr 2026); wait for maturity |
| Databricks Apps module | Provider | Borderline; low priority until more mature |
| Data Quality Monitor module | Provider | Operational/data-engineering; not infrastructure |
| Environments settings | Provider | Single settings; not module-worthy |
| Azure naming module | SRA | Naming is caller's concern, not module's |
| Separate test files per GovCloud shard | SRA | Our approach (multiple run blocks) is more concise |
| `prevent_destroy` as input | Monorepo | Lifecycle meta-argument; caller's choice at the root |
| Provider version bump to >= 1.84 | Monorepo | Our 1.50 is correct per Rule 6.1 unless specific evidence |

---

## Priority-ordered action list

| # | Action | Type | Effort |
|---|---|---|---|
| 1 | Build `dbx-workspace-sql-warehouse` | New module | Small (one resource + permissions) |
| 2 | Build `aws-workspace-restrictive-root-bucket` | New module | Small (one resource, policy template from SRA) |
| 3 | Build `dbx-account-network-policy` | New module | Tiny (one resource) |
| 4 | Add `force_destroy` input to storage modules | Enhancement | Tiny (3 modules, 1 variable each) |
| 5 | Add `isolation_mode` input to UC storage credential modules | Enhancement | Tiny (3 modules, 1 variable each) |
| 6 | Verify PrivateLink regional coverage | Verification | Small |
| 7 | Build `aws-account-network-serverless-privatelink` | New module | Medium (NLB + endpoint service pattern) |
| 8 | Build `gcp-account-vpc-service-controls` | New module | Medium (GCP IAM + perimeter) |
| 9 | Build `dbx-workspace-lakebase` | New module | Medium (7 resources; wait for GA) |
