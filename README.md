# Databricks Terraform Modules

Reusable Terraform modules for provisioning Databricks infrastructure across AWS, Azure, and GCP.

## Structure

```
<cloud>-<surface>-<name>/     # Module directories at repo root
docs/                          # Rules, catalog, and research documents
```

**Naming convention:** `<cloud>-<surface>-<name>` where:
- `<cloud>` ∈ { `aws`, `azure`, `gcp`, `dbx` } — `dbx` = cloud-agnostic Databricks
- `<surface>` ∈ { `account`, `uc`, `workspace` } — provider API surface
- `<name>` — the abstraction (e.g., `workspace-credentials`, `network-vpc`, `sql-warehouse`)

## Using a module

```hcl
module "workspace_credentials" {
  source = "git::https://github.com/<org>/Databricks-Terraform-Modules.git//aws-account-workspace-credentials?ref=v1.0.0"

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id = var.databricks_account_id
  aws_partition         = "aws"
  databricks_gov_shard  = null
  role_name             = "databricks-cross-account"
  credentials_name      = "prod-creds"
}
```

Each module's README documents inputs, outputs, minimum tier, provider configuration, and when to use / when not to use.

## Module catalog

| Layer | Cloud | Count |
|---|---|---|
| Account | AWS | 16 |
| Account | Azure | 9 |
| Account | GCP | 10 |
| Unity Catalog | AWS / Azure / GCP / Agnostic | 8 |
| Workspace | Agnostic | 8 |
| **Total** | | **51** |

Full catalog with purpose and resources: [docs/MODULE_CANDIDATES.md](./docs/MODULE_CANDIDATES.md)

## Rules

Modules are authored against two rules documents:
- [docs/TERRAFORM_RULES.md](./docs/TERRAFORM_RULES.md) — general Terraform module rules
- [docs/DATABRICKS_RULES.md](./docs/DATABRICKS_RULES.md) — Databricks-specific extensions

## Testing

Every module ships with:
- **Static analysis:** `terraform fmt`, `terraform validate`, TFLint, tfsec, Checkov
- **Unit tests:** `tests/plan.tftest.hcl` — `mock_provider` + `command = plan`. No credentials required.
- **Integration tests:** `tests/integration.tftest.hcl` — `command = apply` against real infrastructure. Credential-gated.

Run unit tests:
```bash
cd <module-name>
terraform init -backend=false
terraform test
```

## Pre-commit

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## GovCloud support

AWS modules support commercial, GovCloud civilian (FedRAMP High), and GovCloud DoD (IL5) via the `databricks_gov_shard` input. All ARNs, endpoint names, and account IDs are computed from this input — no separate module tree for GovCloud.

## Contributing

1. Follow the naming convention and standard file layout (see any existing module)
2. Every module must have: `versions.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `README.md`, `CHANGELOG.md`, `examples/basic/`, `tests/plan.tftest.hcl`
3. All 6 gates must pass before merge
4. Add your module to `CODEOWNERS`
