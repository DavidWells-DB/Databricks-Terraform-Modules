# Basic Example

This example creates a Databricks SQL warehouse with:
- Small cluster size
- PRO warehouse type
- Auto-scaling from 1 to 2 clusters
- Cost-optimized spot policy
- Photon enabled
- Permission grant for the "users" group

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Set the following variables via environment variables, `terraform.tfvars`, or `-var` flags:
- `databricks_workspace_host` — your workspace URL
- `databricks_workspace_token` — a personal access token or service principal token

## Outputs

- `warehouse_id` — the SQL warehouse ID
- `jdbc_url` — JDBC connection URL
- `data_source_id` — data source ID for SQL API operations
