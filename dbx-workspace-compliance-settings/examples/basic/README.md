# Example: basic

Minimum invocation of the `dbx-workspace-compliance-settings` module enabling the full compliance hardening baseline: Compliance Security Profile (HIPAA), Enhanced Security Monitoring, Automatic Cluster Update (Sunday at 02:00 UTC), and both legacy access/DBFS controls.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your workspace URL and service principal credentials.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks` workspace-level provider at the root.
- Enabling all five compliance settings in a single module call.
- Passing an optional maintenance window for automatic cluster updates.

## Outputs

- `compliance_security_profile_enabled` — confirms CSP was applied.
- `compliance_standards` — echoes the compliance standards applied.
- `legacy_access_disabled` — confirms legacy access was disabled.
- `legacy_dbfs_disabled` — confirms legacy DBFS was disabled.

## Important

Enabling `compliance_security_profile_enabled = true` is a **permanent, one-way operation**. The Compliance Security Profile cannot be disabled once applied. Do not apply this example against a workspace unless you intend for CSP to be permanently active.
