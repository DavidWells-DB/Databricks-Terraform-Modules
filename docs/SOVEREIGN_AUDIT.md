# Sovereign / Regulated Cloud Audit

**Scope:** Module tier only (this repo). Findings are independent verification against source code;
nothing is taken from the downstream review on trust.  
**Date:** 2026-06-23  
**Method:** Read-only; no code was modified.

---

## 1. Verdict table

| # | Finding | Verdict | Evidence |
|---|---|---|---|
| 1 | AWS modules handle gov correctly via `databricks_gov_shard` | **Confirmed with caveats** | See §2 |
| 2 | Azure modules do not handle gov (no `environment`/`usgovernment` parameter) | **Confirmed** | Zero hits for `environment`, `usgovernment`, `usgovvirginia`, `IL5` in any `azure-*` `.tf` file |
| 3 | `azure-account-network-private-endpoints` hardcodes `privatelink.azuredatabricks.net` | **Confirmed** | `azure-account-network-private-endpoints/main.tf:4` |
| 4 | Azure Gov only partially considered (CMK variable mentions IL5 but networking not addressed) | **Confirmed, and wider than reported** | `azure-account-workspace-storage/variables.tf:42`; `azure-account-encryption-keys/main.tf:181` also hardcodes a commercial DNS zone |

---

## 2. AWS — sovereign readiness

### What is in place

Every AWS module that constructs ARNs, IAM trust policies, or VPC endpoint service attachment URIs
has a `databricks_gov_shard` input (`null` | `"civilian"` | `"dod"`) and maps it to the correct
Databricks control-plane AWS account ID:

| Shard | Account ID | Source |
|---|---|---|
| `null` (commercial) | `414351767826` | e.g. `aws-account-workspace-credentials/locals.tf:8` |
| `"civilian"` | `044793339203` | `aws-account-workspace-credentials/locals.tf:6` |
| `"dod"` | `170661010020` | `aws-account-workspace-credentials/locals.tf:7` |

Modules with `databricks_gov_shard` **and** explicit `aws_partition` as separate inputs (used to
construct ARNs):

| Module | gov_shard | aws_partition | ARN or identity use |
|---|---|---|---|
| `aws-account-workspace-credentials` | ✓ | ✓ | IAM role trust policy principal |
| `aws-account-workspace-storage` | ✓ | ✓ | S3 bucket policy principal |
| `aws-account-encryption-keys` | ✓ | ✓ | KMS key policy principal (`locals.tf:11`) |
| `aws-account-log-delivery` | ✓ | ✓ | `databricks_aws_assume_role_policy` + `databricks_aws_bucket_policy` data sources (`main.tf:76,91`) |
| `aws-account-network-serverless-privatelink` | ✓ | ✓ | VPC endpoint service allowed principal ARN (`locals.tf:15`) |
| `aws-uc-storage-credential` | ✓ | ✓ | UC master role ARN; `databricks_aws_unity_catalog_policy` + assume-role policy data sources |
| `aws-workspace-restrictive-root-bucket` | ✓ | ✓ | S3 bucket policy principal |

Modules with `databricks_gov_shard` that **derive** `aws_partition` internally or have no ARN
construction:

| Module | Notes |
|---|---|
| `aws-account-network-vpc-endpoints` | Derives `aws_partition` in `locals.tf:4` from `gov_shard`; used in endpoint policy ARN |
| `aws-account-network-privatelink-endpoints` | Resolves VPC endpoint service attachment URIs from `gov_shard`; no ARN construction |
| `aws-account-network-vpc` | Computes `databricks_account_host` as an output only (`locals.tf:6-9`); no ARN construction |
| `aws-account-workspace` | Computes `databricks_host` as an output only (`locals.tf:4-8`); helps caller validate provider config |
| `aws-account-workspace-serverless` | Same pattern as above (`locals.tf:4-8`) |

Account-host outputs in `aws-account-vpc`, `aws-account-workspace`, and
`aws-account-workspace-serverless` correctly differentiate all three shards:

```
civilian → "https://accounts.cloud.databricks.us"
dod      → "https://accounts-dod.cloud.databricks.mil"
null     → "https://accounts.cloud.databricks.com"
```

This matches the verified platform facts.

UC master role ARNs in `aws-uc-storage-credential/locals.tf:7-9` are hardcoded with full ARNs
including the correct `aws-us-gov` partition for GovCloud shards — verified consistent with
Databricks documentation.

Variable validations are consistent: every module that accepts `databricks_gov_shard` validates
`null || contains(["civilian", "dod"], …)`; every module that accepts `aws_partition` validates
`contains(["aws", "aws-us-gov"], …)`.

Tests in `aws-account-workspace-credentials` and `aws-account-network-privatelink-endpoints` each
exercise all three shards (commercial / civilian / dod) with explicit `assert` blocks on the
derived identity values. Evidence: `aws-account-workspace-credentials/tests/plan.tftest.hcl:38-63`
and `aws-account-network-privatelink-endpoints/tests/plan.tftest.hcl:41-94`.

### Caveats (verified gaps)

**Gap AWS-1 — No cross-validation between `aws_partition` and `databricks_gov_shard` (MEDIUM)**

In all modules that accept both as independent inputs (7 modules listed above), there is no
validation rule that enforces consistency. A caller can pass:

```hcl
aws_partition        = "aws"       # commercial partition
databricks_gov_shard = "civilian"  # but civilian shard account ID
```

This produces an IAM trust-policy principal of `arn:aws:iam::044793339203:root` — a `aws`-partition
ARN pointing at the GovCloud control-plane account. AWS will silently reject assume-role from this
principal. The inverse (`aws-us-gov` partition, `null` shard) similarly produces a broken ARN.
Neither direction produces an error at `terraform plan` time; the failure surfaces only at `apply`
when IAM rejects the trust policy.

**Gap AWS-2 — Gov-path unit tests missing from identity-critical modules (LOW)**

Of the seven modules that build ARNs using `databricks_gov_shard` + `aws_partition`,
only `aws-account-workspace-credentials` has explicit gov-path test runs. The following
modules have no tests that exercise `databricks_gov_shard = "civilian"` or `"dod"`:

- `aws-account-encryption-keys`
- `aws-account-workspace-storage`
- `aws-account-log-delivery`
- `aws-uc-storage-credential`
- `aws-workspace-restrictive-root-bucket`
- `aws-account-network-serverless-privatelink`

The `gov_shard`→account-ID mapping logic is duplicated across all of them; a copy-paste error
in any one would not be caught.

---

## 3. Azure — sovereign readiness

### What is in place

**Nothing at the module code level.** No `azure-*` module accepts an
`environment`, `azure_environment`, or equivalent parameter. This is an explicit, documented design
decision: the `azure-account-workspace/README.md:27` and
`azure-account-network-private-endpoints/README.md:29-38` both state that Azure Government is a
provider-level concern handled by `environment = "usgovernment"` on the `azurerm` provider.

That design decision is **correct for most Azure resources** — the provider's environment setting
transparently routes API calls to Azure Government endpoints. However, it is **incorrect for
private DNS zone names**, which are literal string values in resource definitions that the
provider cannot reroute.

### Confirmed defects

**Defect AZ-1 — `azure-account-network-private-endpoints` hardcodes commercial DNS zone name
(HIGH)**

`azure-account-network-private-endpoints/main.tf:4`:
```hcl
resource "azurerm_private_dns_zone" "this" {
  name = "privatelink.azuredatabricks.net"
```

Azure Government uses the suffix `privatelink.azuredatabricks.azure.us`. Deploying this module
in MAG (`usgovvirginia` or `usgovarizona`) creates a DNS zone with the wrong suffix. Private
endpoints register their A records into this zone; clients resolve the workspace hostname through
it. With the wrong zone name:
- The private DNS zone is created successfully (Azure does not validate zone name format against
  environment)
- Private endpoints are created and appear healthy
- **Clients cannot resolve the workspace URL** because the zone name does not match the
  workspace's FQDN suffix in Azure Government

The module README at line 38 states:
> "No module-level changes are needed for Azure Government; the `azurerm` provider transparently
> routes to government endpoints."

This claim is incorrect. The provider routes API calls; it does not rewrite resource attribute
values. **The README actively misleads callers** into deploying a broken configuration with
confidence.

**Defect AZ-2 — `azure-account-encryption-keys` hardcodes commercial Key Vault private DNS zone
name (HIGH, conditional)**

`azure-account-encryption-keys/main.tf:181`:
```hcl
resource "azurerm_private_dns_zone" "key_vault" {
  count = var.private_endpoint != null ? 1 : 0
  name  = "privatelink.vaultcore.azure.net"
```

Azure Government uses `privatelink.vaultcore.usgovcloudapi.net`. This block is conditional
(`var.private_endpoint != null`), so callers not using the PE option are unaffected. Callers
who do pass `private_endpoint` in MAG get a wrong-suffix DNS zone and Key Vault access fails
over the private path.

### Known limitations of the provider-only approach

For reference, these Azure attributes ARE safely handled by the provider's `environment` setting
and require no module-level changes:

- `azurerm_databricks_workspace` resource — provider routes to the correct ARM endpoint
- All Azure resource CRUD operations — provider handles endpoint routing
- Service tags (`AzureDatabricks`, `Storage.*`) in firewall rules — these are global and
  environment-agnostic
- Subnet delegation (`Microsoft.Databricks/workspaces`) — same across environments
- ARM resource ID patterns (`/subscriptions/.../providers/Microsoft.Databricks/...`) — same
  structure, provider handles routing

**What must be fixed at module level:** any literal string that is environment-specific and is
not an API call — specifically, private DNS zone names.

### Out-of-scope modules for MAG

Per platform facts, Unity Catalog and Databricks SQL are not available in MAG
(Azure Government). The following modules are therefore out of scope for MAG and need not be
remediated:

- `azure-uc-storage-credential` — UC not available in MAG
- `dbx-uc-catalog`, `dbx-uc-schema`, `dbx-uc-external-location`, `dbx-uc-metastore`,
  `dbx-uc-metastore-assignment` — same
- `dbx-workspace-sql-warehouse` — Databricks SQL not available in MAG
- `azure-account-workspace-serverless` — serverless compute is not generally available in MAG

None of these modules currently include a "When NOT to use" note for MAG. This is a
documentation gap, not a code defect — the platform will reject deployment noisily at apply
time.

---

## 4. GCP — sovereign readiness

Databricks has no US-Government / FedRAMP offering on GCP. Confirmed: no `gov`, `government`,
`fedramp`, or `sovereign` term appears in any `gcp-*` `.tf` file. The one occurrence in
`gcp-account-vpc-service-controls/README.md` uses "govern" in the generic sense ("governs which
GCP services are accessible"). No GCP module implies or claims gov support.

---

## 5. Additional gaps ranked by severity

| Severity | ID | Gap | Affected files |
|---|---|---|---|
| HIGH | AZ-1 | `azure-account-network-private-endpoints` hardcodes `privatelink.azuredatabricks.net`; README incorrectly claims no module changes needed for Azure Gov | `main.tf:4`, `README.md:38` |
| HIGH | AZ-2 | `azure-account-encryption-keys` hardcodes `privatelink.vaultcore.azure.net` (conditional on `private_endpoint != null`) | `main.tf:181` |
| MEDIUM | AWS-1 | No cross-validation between `aws_partition` and `databricks_gov_shard` in the 7 modules that accept both as independent inputs | `variables.tf` in credentials, encryption-keys, log-delivery, workspace-storage, serverless-privatelink, uc-storage-credential, workspace-restrictive-root-bucket |
| LOW | AWS-2 | Gov-path unit tests absent for `aws-account-encryption-keys`, `aws-account-workspace-storage`, `aws-account-log-delivery`, `aws-uc-storage-credential`, `aws-workspace-restrictive-root-bucket`, `aws-account-network-serverless-privatelink` | `tests/plan.tftest.hcl` in each |
| LOW | AZ-3 | `azure-uc-storage-credential`, `azure-account-workspace-serverless`, and UC/SQL `dbx-*` modules have no MAG out-of-scope note | `README.md` files |

---

## 6. Remediation plan: Azure Government support at the module layer

### Scope

Only two modules require code changes. Everything else either works via provider routing or is
out of scope for MAG.

### Module: `azure-account-network-private-endpoints`

**Changes required:**

1. Add an `azure_environment` variable (required — no default):

```hcl
variable "azure_environment" {
  type        = string
  description = "Azure environment. \"public\" for commercial Azure; \"usgovernment\" for Azure Government (MAG). Must match the environment set on the azurerm provider. Controls the private DNS zone suffix for Databricks Private Link."
  nullable    = false
  validation {
    condition     = contains(["public", "usgovernment"], var.azure_environment)
    error_message = "azure_environment must be \"public\" or \"usgovernment\"."
  }
}
```

2. Add a local for the DNS zone name:

```hcl
locals {
  # Azure Government uses a different private DNS zone suffix for Databricks.
  # Commercial: privatelink.azuredatabricks.net
  # MAG:        privatelink.azuredatabricks.azure.us
  databricks_private_dns_zone_name = (
    var.azure_environment == "usgovernment"
    ? "privatelink.azuredatabricks.azure.us"
    : "privatelink.azuredatabricks.net"
  )
  # ... existing locals ...
}
```

3. Replace the hardcoded string in `main.tf:4`:

```hcl
resource "azurerm_private_dns_zone" "this" {
  name                = local.databricks_private_dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
```

4. Correct `README.md:38`: replace the false "no module-level changes needed" claim with an
   accurate note:

```markdown
For **Azure Government**, set `azure_environment = "usgovernment"` in addition to configuring
the `azurerm` provider with `environment = "usgovernment"`. The private DNS zone name differs
between commercial (`privatelink.azuredatabricks.net`) and MAG
(`privatelink.azuredatabricks.azure.us`); the module handles this automatically when
`azure_environment` is set correctly.
```

### Module: `azure-account-encryption-keys`

**Changes required:**

1. Add the same required `azure_environment` variable.

2. Add a local for the Key Vault DNS zone name:

```hcl
locals {
  # Key Vault private DNS zone suffix differs by environment:
  # Commercial: privatelink.vaultcore.azure.net
  # MAG:        privatelink.vaultcore.usgovcloudapi.net
  key_vault_private_dns_zone_name = (
    var.azure_environment == "usgovernment"
    ? "privatelink.vaultcore.usgovcloudapi.net"
    : "privatelink.vaultcore.azure.net"
  )
  # ... existing locals ...
}
```

3. Replace `main.tf:181`:

```hcl
resource "azurerm_private_dns_zone" "key_vault" {
  count               = var.private_endpoint != null ? 1 : 0
  name                = local.key_vault_private_dns_zone_name
  resource_group_name = local.pe_resource_group_name
  tags                = var.tags
}
```

### Other modules (documentation only)

Add "When NOT to use" notes to `azure-uc-storage-credential`, `azure-account-workspace-serverless`,
and the `dbx-uc-*` / `dbx-workspace-sql-warehouse` README files stating MAG unsupported scope.

### AWS cross-validation (Gap AWS-1)

Add a cross-validation rule to each of the 7 affected modules. Example for
`aws-account-workspace-credentials/variables.tf`:

```hcl
# Add to existing variable "databricks_gov_shard" validation, or as a separate
# locals-based check. Terraform does not support cross-variable validations natively,
# so this requires either a precondition on a resource or a combined check in a local.

locals {
  _partition_shard_consistent = (
    (var.databricks_gov_shard != null && var.aws_partition == "aws-us-gov") ||
    (var.databricks_gov_shard == null && var.aws_partition == "aws")
  )
}

# Then add a lifecycle precondition to a resource:
lifecycle {
  precondition {
    condition     = local._partition_shard_consistent
    error_message = "aws_partition and databricks_gov_shard are inconsistent: set aws_partition = \"aws-us-gov\" when databricks_gov_shard is \"civilian\" or \"dod\", and aws_partition = \"aws\" when databricks_gov_shard is null."
  }
}
```

---

## 7. Items that could not be verified

**Cannot verify in this repo:**

1. **Whether the hardcoded GovCloud PrivateLink service attachment URIs are still current.**
   The `aws-account-network-privatelink-endpoints/locals.tf` values were sourced from
   Databricks documentation but cannot be confirmed against the live API from module code
   alone. Any URI rotation would require an out-of-band check against
   `https://docs.databricks.com/aws/en/resources/ip-domain-region`.

2. **Whether `databricks_mws_log_delivery` is available in GovCloud.** The `aws-account-log-delivery`
   module appears structurally correct for GovCloud, but Databricks documentation does not
   clearly list which MWS APIs are available in each GovCloud shard. If log delivery is not
   available in the DoD shard, the module would fail at apply with a provider API error, not
   a plan-time error.

3. **Whether `azure-account-network-connectivity-config` (NCC) is supported in MAG.** The
   module uses `databricks_mws_network_connectivity_config` which requires an account-level
   Databricks provider. MAG support for this resource is not confirmed here.

4. **Correct DNS zone suffix for `browser_authentication` private endpoint in MAG.** The
   `azure-account-network-private-endpoints` module creates a `browser_authentication` endpoint
   (`enable_browser_auth_pe = true`). It is possible this endpoint uses the same DNS zone as
   the `databricks_ui_api` endpoints, but this was not confirmed against Azure Government
   documentation.

5. **UC master role ARN validity in GovCloud.** The three ARNs hardcoded in
   `aws-uc-storage-credential/locals.tf:7-9` were not independently confirmed against the
   Databricks platform — they are taken at face value from the source comments which cite
   `https://docs.databricks.com/aws/en/security/privacy/gov-cloud`.
