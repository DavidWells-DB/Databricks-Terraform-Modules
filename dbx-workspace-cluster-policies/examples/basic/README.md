# Example: basic

Minimum invocation of the `dbx-workspace-cluster-policies` module against a Databricks workspace.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your workspace URL and service principal credentials.
2. Ensure the service principal has workspace admin or Cluster Policy Create permission.
3. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring the `databricks.workspace` provider at the root and passing it to the module.
- Creating a custom-definition policy (`cost-controlled`) using Policy Definition Language JSON.
- Creating a policy-family-based policy (`personal-compute`) that inherits from the `personal-vm` Databricks-managed family and overrides `autotermination_minutes`.
- Assigning `CAN_USE` permission to workspace groups for each policy.

## Outputs

- `policy_ids` — Map of policy name to Databricks cluster policy resource ID.
- `policy_policy_ids` — Map of policy name to the Databricks-internal `policy_id` (reference this in `databricks_cluster.policy_id`).
