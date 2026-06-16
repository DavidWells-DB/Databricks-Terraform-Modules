# dbx-workspace-secret-scope

Creates one or more Databricks secret scopes within a workspace. Manages scope structure and ACL bootstrap (via `initial_manage_principal`) only — secret values are intentionally out of scope.

## What this module abstracts

"The secret scope structure a workspace uses to organize secrets" — a repeatable, workspace-level operational concern. The module accepts a map of scope names to configurations, enabling teams to declare all their scopes in one place and apply them together without wiring per-scope provider references or repeating the `for_each` pattern.

## When to use

- You're bootstrapping a new workspace and need one or more named secret scopes before populating secrets.
- You want a single module call to register all scopes, with optional Azure Key Vault backing per scope.
- You need to grant initial `MANAGE` permission to all workspace users (`initial_manage_principal = "users"`).

## When NOT to use

- You need to store actual secret values — use `databricks_secret` resources directly at the root composition or via a separate secret-management module.
- You need to manage fine-grained secret ACLs beyond the initial principal — use `databricks_secret_acl` at the root composition after scope creation.
- The workspace has only one scope and it's managed inline in a larger root composition with no reuse need.

## Minimum platform tier

**Premium.** Secret scopes with ACL enforcement require Premium tier. On Standard-tier workspaces the API may accept the scope but ACL enforcement is absent. See DATABRICKS_RULES.md Rule 2.3 and Rule 4.1.

## Provider configuration

This module declares `configuration_aliases = [databricks.workspace]` per DATABRICKS_RULES.md Rule 2.2. The caller MUST supply a `databricks.workspace` provider configured against the target workspace URL.

This module uses the **Workspace** API surface only (DATABRICKS_RULES.md Rule 1.1). It is cloud-agnostic — the same module works for AWS, Azure, and GCP workspaces. Azure Key Vault-backed scopes require Azure-specific authentication (not PAT) on the workspace provider.

## Azure Key Vault-backed scopes

Provide `keyvault_metadata` for any scope that should be backed by Azure Key Vault:

```hcl
scopes = {
  "my-kv-scope" = {
    keyvault_metadata = {
      resource_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/my-kv"
      dns_name    = "https://my-kv.vault.azure.net/"
    }
  }
}
```

Azure Key Vault-backed scopes require that the workspace provider uses Azure-native authentication (service principal or managed identity), not a PAT token.

## Generated reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.14 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_databricks.workspace"></a> [databricks.workspace](#provider\_databricks.workspace) | >= 1.14 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [databricks_secret_scope.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/secret_scope) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_scopes"></a> [scopes](#input\_scopes) | Map of secret scope name to configuration. Each key is the scope name (must be unique within the workspace, max 128 chars, alphanumeric/dash/underscore/period). Set initial\_manage\_principal to "users" to grant all workspace users MANAGE on the scope; omit to grant only the calling principal. Provide keyvault\_metadata only for Azure Key Vault-backed scopes — resource\_id is the Azure KV resource ID and dns\_name is the vault URI. | <pre>map(object({<br/>    initial_manage_principal = optional(string, null)<br/>    keyvault_metadata = optional(object({<br/>      resource_id = string<br/>      dns_name    = string<br/>    }), null)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_scope_backend_types"></a> [scope\_backend\_types](#output\_scope\_backend\_types) | Map of scope name to backend type (DATABRICKS or AZURE\_KEYVAULT). Useful for verifying that Azure Key Vault-backed scopes were registered correctly. |
| <a name="output_scope_ids"></a> [scope\_ids](#output\_scope\_ids) | Map of scope name to Databricks secret scope object ID. Useful for constructing ACL rules or debugging scope registration. |
| <a name="output_scope_names"></a> [scope\_names](#output\_scope\_names) | Set of secret scope names created by this module. Useful for downstream modules or resources that reference these scopes by name. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Valid scope map creates expected resources with correct names
- Scope name validation rejects names longer than 128 chars
- Scope name validation rejects names with invalid characters
- `initial_manage_principal` validation rejects values other than `null` or `"users"`
- Multiple scopes are all created via `for_each`

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks workspace) verifies actual scope creation and backend_type. It is credential-gated and includes a placeholder for the tier-failure case per DATABRICKS_RULES.md Rule 4.1.
