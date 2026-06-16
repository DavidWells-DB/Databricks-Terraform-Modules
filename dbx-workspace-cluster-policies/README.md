# dbx-workspace-cluster-policies

Creates Databricks cluster policies within a workspace and assigns access to those policies via `databricks_permissions`.

## What this module abstracts

"Cluster policy governance" — the combination of defining constraint rules that clusters must comply with and granting groups/users the right to create clusters using those policies. Managing policies and their permissions separately creates thin wrappers; this module provides the complete governance primitive.

## When to use

- You need to standardize cluster configurations across a workspace (autotermination, DBU limits, allowed node types, Spark settings).
- You want to restrict which users or groups can create clusters under specific cost, security, or operational constraints.
- You are adopting Databricks-managed policy families and want to apply targeted overrides.

## When NOT to use

- You need to manage cluster policy families themselves — those are Databricks-managed and not configurable via Terraform.
- You have no governance requirements and want unrestricted cluster creation — use no policy.
- You are assigning policies to specific cluster resources (set `policy_id` on a `databricks_cluster` resource directly in your root composition instead).

## Minimum platform tier

**Premium.** Cluster policies with access controls (permissions) require Premium tier. Applying this module against a Standard-tier workspace will fail at apply time when the provider attempts to create policies with ACLs. See DATABRICKS_RULES.md Rules 2.3 and 4.1.

## Provider configuration

This module is **workspace-surface only** and requires `databricks.workspace` configured against the target workspace URL. It uses `configuration_aliases = [databricks.workspace]` per DATABRICKS_RULES.md Rule 2.2. The caller must supply:

```hcl
provider "databricks" {
  alias = "workspace"
  host  = "<workspace-url>"
}

module "cluster_policies" {
  source = "..."

  providers = {
    databricks.workspace = databricks.workspace
  }

  policies = { ... }
}
```

No account-level provider is required. This module is cloud-agnostic (AWS, Azure, GCP).

## Policy definition approaches

**Custom definition** — full control via Databricks Policy Definition Language JSON:

```hcl
policies = {
  "cost-controlled" = {
    definition = jsonencode({
      "dbus_per_hour" = { type = "range", maxValue = 10 }
      "autotermination_minutes" = { type = "fixed", value = 20, hidden = true }
    })
  }
}
```

**Policy family inheritance** — extend a Databricks-managed baseline:

```hcl
policies = {
  "personal-compute" = {
    policy_family_id                   = "personal-vm"
    policy_family_definition_overrides = jsonencode({
      "autotermination_minutes" = { type = "fixed", value = 120, hidden = true }
    })
  }
}
```

Exactly one of `definition` or `policy_family_id` must be set per policy entry; the module validates this at plan time.

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
| [databricks_cluster_policy.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/cluster_policy) | resource |
| [databricks_permissions.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/permissions) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_policies"></a> [policies](#input\_policies) | Map of cluster policy name to its configuration. Map key becomes the policy name.<br/>Provide exactly one of `definition` or `policy_family_id` per entry:<br/>- `definition`: JSON-encoded policy rules in Databricks Policy Definition Language.<br/>- `policy_family_id`: ID of a Databricks-managed policy family to inherit from.<br/>  Use `policy_family_definition_overrides` (JSON string) to override specific fields.<br/>- `description`: Optional human-readable description.<br/>- `max_clusters_per_user`: Optional integer limit on clusters per user (> 0). | <pre>map(object({<br/>    # Exactly one of definition or policy_family_id must be provided per policy entry.<br/>    # Use definition for fully custom JSON policy definitions.<br/>    # Use policy_family_id (+ optional overrides) to inherit from a Databricks policy family.<br/>    description = optional(string)<br/>    definition  = optional(string)<br/>    # policy_family_id values are defined by Databricks and returned by the<br/>    # GET /api/2.0/policies/clusters/policy-families API endpoint.<br/>    policy_family_id = optional(string)<br/>    # JSON string of overrides applied on top of the inherited policy family definition.<br/>    policy_family_definition_overrides = optional(string)<br/>    max_clusters_per_user              = optional(number)<br/>  }))</pre> | n/a | yes |
| <a name="input_policy_assignments"></a> [policy\_assignments](#input\_policy\_assignments) | Map of policy name to its permission assignments. Map keys must match keys in `policies`.<br/>Each entry's `access_controls` is a list of principals granted CAN\_USE on that policy.<br/>Each principal object must set exactly one of `group_name`, `user_name`, or `service_principal_name`.<br/>Policies not present in this map receive no explicit permissions (Databricks default applies). | <pre>map(object({<br/>    # List of principals (group names, user names, or service principal names)<br/>    # granted CAN_USE on this policy. Each entry is an object with exactly one<br/>    # of group_name, user_name, or service_principal_name.<br/>    access_controls = list(object({<br/>      group_name             = optional(string)<br/>      user_name              = optional(string)<br/>      service_principal_name = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_policy_ids"></a> [policy\_ids](#output\_policy\_ids) | Map of policy name to Databricks cluster policy ID. Pass individual IDs to compute resources that require a policy\_id. |
| <a name="output_policy_names"></a> [policy\_names](#output\_policy\_names) | List of created cluster policy names, in the order returned by for\_each iteration. |
| <a name="output_policy_policy_ids"></a> [policy\_policy\_ids](#output\_policy\_policy\_ids) | Map of policy name to the Databricks-internal policy\_id (distinct from the resource `id`). Required when referencing a policy in cluster definitions. |
<!-- END_TF_DOCS -->

## Example

See [`examples/basic/`](./examples/basic/).

## Tests

`tests/plan.tftest.hcl` exercises (no credentials required; uses `mock_provider`):
- Custom `definition`-based policy planned with expected name and definition.
- Policy-family-based policy planned with expected `policy_family_id`.
- Mutual exclusivity validation: both `definition` and `policy_family_id` set is rejected.
- Mutual exclusivity validation: neither set is rejected.
- `policy_family_definition_overrides` without `policy_family_id` is rejected.
- `max_clusters_per_user = 0` is rejected; positive value passes.
- Policy name length bounds validation (empty key rejected, key over 100 chars rejected).
- `policy_assignments` with two principals of the same policy is planned correctly.
- access_control with multiple principal selectors set is rejected.
- access_control with no principal selector set is rejected.

Run with `terraform test` from the module root.

An apply-command integration test (against a real Databricks workspace) verifies actual policy creation and permission assignment. Credential-gated; includes a tier-failure case per DATABRICKS_RULES.md Rule 4.1.
