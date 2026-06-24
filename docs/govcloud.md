# GovCloud support

AWS modules support three deployment targets controlled by a single `databricks_gov_shard` input variable:

| Value | Environment | Compliance |
|---|---|---|
| `null` | Commercial | — |
| `"civilian"` | AWS GovCloud (us-gov-west-1) | FedRAMP High |
| `"dod"` | AWS GovCloud (us-gov-west-1) | DoD IL5 |

No separate module tree exists for GovCloud — the same modules cover all three targets.

## What changes per shard

### Databricks AWS account ID

IAM cross-account and assume-role trust policies must trust the correct Databricks control-plane account:

| Shard | Account ID |
|---|---|
| commercial | `414351767826` |
| `"civilian"` | `044793339203` |
| `"dod"` | `170661010020` |

Affected modules: `aws-account-workspace-credentials`, `aws-account-workspace-storage`, `aws-account-encryption-keys`, `aws-account-log-delivery`, `aws-account-network-serverless-privatelink`, `aws-account-workspace-serverless`.

### AWS partition

ARNs in GovCloud use the `aws-us-gov` partition. Modules that accept an explicit `aws_partition` variable expect `"aws-us-gov"` when `databricks_gov_shard` is set. Some modules (e.g., `aws-account-network-vpc-endpoints`) derive the partition internally from `databricks_gov_shard` and don't expose a separate input.

### PrivateLink endpoint service attachment URIs

Both GovCloud shards operate in `us-gov-west-1` but use distinct VPC endpoint service IDs:

| Endpoint type | Shard | Service name |
|---|---|---|
| Workspace (REST) | `civilian` | `com.amazonaws.vpce.us-gov-west-1.vpce-svc-0f25e28401cbc9418` |
| Workspace (REST) | `dod` | `com.amazonaws.vpce.us-gov-west-1.vpce-svc-08fddf710780b2a54` |
| SCC relay | `civilian` | `com.amazonaws.vpce.us-gov-west-1.vpce-svc-05f27abef1a1a3faa` |
| SCC relay | `dod` | `com.amazonaws.vpce.us-gov-west-1.vpce-svc-05c210a2feea23ad7` |

Affected modules: `aws-account-network-privatelink-endpoints`.

> **Note:** Service Direct (the third PrivateLink endpoint type) is not available in GovCloud. Passing `custom_service_attachment_uris.service_direct` will enable it for edge cases but it is not a supported configuration.

### Unity Catalog storage credential role ARN

| Shard | UC master role ARN |
|---|---|
| commercial | `arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL` |
| `"civilian"` | `arn:aws-us-gov:iam::044793339203:role/unity-catalog-prod-UCMasterRole-1QRFA8SGY15OJ` |
| `"dod"` | `arn:aws-us-gov:iam::170661010020:role/unity-catalog-prod-UCMasterRole-1DI6DL6ZP26AS` |

Affected modules: `aws-uc-storage-credential`.

## Modules with GovCloud support

The following AWS modules accept `databricks_gov_shard`:

- `aws-account-encryption-keys`
- `aws-account-log-delivery`
- `aws-account-network-privatelink-endpoints`
- `aws-account-network-serverless-privatelink`
- `aws-account-network-vpc`
- `aws-account-network-vpc-endpoints`
- `aws-account-workspace`
- `aws-account-workspace-credentials`
- `aws-account-workspace-serverless`
- `aws-account-workspace-storage`
- `aws-uc-storage-credential`
- `aws-workspace-restrictive-root-bucket`

Pure infrastructure modules that have no Databricks-specific ARNs or account IDs (`aws-account-network-egress-internet`, `aws-account-network-firewall`, `aws-account-network-transit-gateway`, `aws-account-network-vpc-peering`, `aws-account-network-connectivity-config`) work in GovCloud unchanged — deploy them to a GovCloud AWS account without any shard input.

## Usage example

```hcl
# GovCloud civilian (FedRAMP High) workspace credentials
module "workspace_credentials" {
  source = "git::https://github.com/<org>/Databricks-Terraform-Modules.git//aws-account-workspace-credentials?ref=v1.0.0"

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id = var.databricks_account_id
  aws_partition         = "aws-us-gov"    # required for GovCloud
  databricks_gov_shard  = "civilian"      # or "dod" for IL5
  role_name             = "databricks-cross-account"
  credentials_name      = "prod-creds"
}

# GovCloud PrivateLink endpoints — same shard value, no region lookup needed
module "privatelink" {
  source = "git::https://github.com/<org>/Databricks-Terraform-Modules.git//aws-account-network-privatelink-endpoints?ref=v1.0.0"

  providers = {
    aws                  = aws
    databricks.account   = databricks.account
  }

  region               = "us-gov-west-1"
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  databricks_gov_shard = "civilian"    # resolves service attachment URIs automatically
}
```
