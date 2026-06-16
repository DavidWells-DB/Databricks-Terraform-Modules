# Example: basic

Minimum invocation of the `dbx-workspace-network-serverless` module — binds an existing NCC to a workspace with no private endpoint rules and no network policy assignment.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your Databricks account ID, workspace details, and service principal credentials.
2. Run:

   ```
   terraform init
   terraform plan
   terraform apply
   ```

## What this example demonstrates

- Configuring both `databricks.account` and `databricks.workspace` provider aliases at the root.
- Passing both provider aliases to the module.
- Minimum required inputs: `workspace_id` and `network_connectivity_config_id`.

## Extending to private endpoint rules

To add private endpoint rules (e.g. for AWS S3 or Azure Storage), add a `private_endpoint_rules` input to the module call:

```hcl
private_endpoint_rules = [
  {
    key              = "s3-us-east-1"
    endpoint_service = "com.amazonaws.us-east-1.s3"
    resource_names   = ["my-databricks-bucket"]
    enabled          = true
  }
]
```

## Outputs

- `ncc_binding_id` — Composite NCC binding identifier.
- `network_connectivity_config_id` — NCC ID that was bound.
