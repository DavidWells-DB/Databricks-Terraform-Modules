# The Databricks module rules

> **Status: consolidated, 2026-11-04.** This document was NOT in the repository — the rules
> were cited ~200 times across the repos (and in the Blueprints/Components tiers) without
> a source. This page reconstructs each cited rule from the substance carried in the
> citations themselves (module comments, READMEs, CHANGELOGs); every rule lists its
> sources. Rules whose number is cited but whose substance could not be sourced are
> marked **UNVERIFIED** — they are placeholders for the original author to fill, not
> invented content.

The rules govern the **Modules tier** (this repo). The Blueprints tier is governed by its
own spec (`BLUEPRINT_SPEC.md` in the Blueprints repo); where that spec is silent, these
rules apply.

## 1. Module shape

### Rule 1.1 — *(UNVERIFIED)*
Cited twice, no substance found in any citation. **Awaiting the original text.**

### Rule 1.2 — A module encapsulates a complete, indivisible deployment unit
Splitting a coherent unit into thin wrappers forces every caller to re-wire the same
pieces every time. The canonical case: the Azure firewall module owns the firewall
resource, policy, IP group, public IP, route table, and subnet associations as one unit.
*Source: `azure-account-network-firewall/README.md`.*

### Rule 1.4 — Cloud-side and Databricks-side halves of one object belong in ONE module
A cloud resource and its Databricks-side registration are an indivisible pair (the
cross-account role and the `databricks_storage_credential`; the VPC and the
`databricks_mws_networks`; the access connector and the credential). Callers consume the
pair through a single module call. *Sources: `azure-uc-storage-credential/main.tf`,
`aws-account-network-vpc/main.tf`, `gcp-account-network-vpc/main.tf`.*

### Rule 1.5 — Sovereignty/GovCloud is a module INPUT, never a separate tree
GovCloud variants are parameterized by input (`databricks_gov_shard`: commercial /
civilian / dod; all ARNs, endpoints, and account IDs derived from it). Provider-level
concerns (e.g. the account host URL) stay in the root composition. No parallel
gov-flavored module directories. *Source: `aws-account-network-vpc/README.md` and
CHANGELOG.*

## 2. Interface

### Rule 2.2 — *(UNVERIFIED)*
Cited ~30 times, no consistent substance found in the citations. **Awaiting the original
text.** (Most citations appear alongside Rule 2.3 as "the Databricks module rules Rule
2.2/2.3" tier-floor references — likely the tier-declaration requirement, but this is
inference, not source.)

### Rule 2.3 — Tier floors are declared in the module README
Where a capability requires a Databricks account tier (Premium for UC-consumed storage,
VPC/VNet peering, custom networking), the README's "Minimum platform tier" section states
it explicitly, because the provider cannot check tier at plan time. *Sources:
`azure-account-workspace-storage/README.md`, `aws-account-network-vpc-peering/README.md`,
`aws-account-network-egress-internet/README.md`.*

### Rule 2.4 — Mutually-exclusive cloud blocks: exactly one, validated
Where a variable accepts per-cloud alternative blocks (`aws_iam_role` /
`azure_managed_identity` / `databricks_gcp_service_account`), exactly ONE may be populated
— enforced by validation, not by documentation alone. *Source:
`dbx-uc-metastore/variables.tf`.*

## 3. Terraform mechanics

### Rule 3.1 — Propagation waits are real, minimum-bounded, and justified
`time_sleep` guards exist only for documented propagation minimums (e.g. the 30s IAM
propagation delay before Databricks validates a trust relationship), with the reason in
a comment. A sleep that gates nothing is a defect. *Sources: `aws-account-workspace/main.tf`,
`gcp-account-workspace/main.tf`, `aws-account-log-delivery/main.tf`.*

### Rule 3.2 — `ignore_changes` is sanctioned for external mutation, with the reason cited
Attributes that Databricks or the cloud account mutate out-of-band (`custom_tags`,
externally-synced identity attributes) are ignored **with a comment naming the mutation**
— never as a blanket drift-suppressor. *Sources: `dbx-workspace-identity/main.tf`,
`aws-account-workspace-serverless/main.tf`.*

### Rule 3.3 — *(UNVERIFIED)*
Cited once, no substance found. **Awaiting the original text.**

## 4. Verification

### Rule 4.1 — Every module ships a credential-gated apply-command test, including the loud-failure case
Beyond plan tests, each module carries an apply-command integration test
(`tests/integration.tftest.hcl`) that runs against a real account, is explicitly
credential-gated (never in credential-free CI), and where applicable includes the
tier-gated failure case so illegality surfaces loudly at apply, not silently.
*Sources: `dbx-uc-schema/README.md`, `aws-account-workspace-serverless/README.md`,
`dbx-workspace-cluster-policies/README.md`.*

---

*Maintenance: when a rule here changes, update this page in the same commit as the code
that relies on it. New rules cite this document; nothing cites an external source for
them anymore.*
