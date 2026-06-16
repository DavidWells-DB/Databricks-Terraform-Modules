# AWS Account Network Serverless PrivateLink Module

This module creates the customer-side AWS infrastructure that enables Databricks serverless compute to reach a customer resource (RDS, Redshift, etc.) over PrivateLink.

## Overview

Databricks serverless compute can connect to customer resources in private subnets via AWS PrivateLink. This module creates:

- **Network Load Balancer (NLB)**: Internal, type "network", forwards traffic to the target resource
- **Target Group**: Points to the customer resource IP address
- **VPC Endpoint Service**: Exposes the NLB as an endpoint service
- **Authorization**: Allows Databricks AWS account to connect to the endpoint service
- **Security Group**: Controls NLB egress to the target resource

## Usage

```hcl
module "serverless_privatelink" {
  source = "path/to/modules/aws-account-network-serverless-privatelink"

  name                  = "databricks-serverless-rds"
  vpc_id                = "vpc-0123456789abcdef0"
  subnet_ids            = ["subnet-abc123", "subnet-def456"]
  target_ip             = "10.0.1.100"
  target_port           = 5432
  databricks_account_id = "00000000-0000-0000-0000-000000000000"
  aws_partition         = "aws"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### GovCloud Example

```hcl
module "serverless_privatelink_gov" {
  source = "path/to/modules/aws-account-network-serverless-privatelink"

  name                  = "databricks-serverless-rds"
  vpc_id                = "vpc-0123456789abcdef0"
  subnet_ids            = ["subnet-abc123"]
  target_ip             = "10.0.1.100"
  target_port           = 5432
  databricks_account_id = "00000000-0000-0000-0000-000000000000"
  aws_partition         = "aws-us-gov"
  databricks_gov_shard  = "civilian"

  tags = {
    Environment = "production"
  }
}
```

## Architecture

```
Databricks Serverless
         |
         | (PrivateLink)
         v
VPC Endpoint Service
         |
         v
   Network Load Balancer
         |
         v
    Target Group
         |
         v
Customer Resource (RDS/Redshift/etc.)
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.7.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Resources

| Name | Type |
|------|------|
| aws_lb | resource |
| aws_lb_listener | resource |
| aws_lb_target_group | resource |
| aws_lb_target_group_attachment | resource |
| aws_security_group | resource |
| aws_vpc_endpoint_service | resource |
| aws_vpc_endpoint_service_allowed_principal | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Resource naming prefix. Used to name the NLB, target group, security group, and VPC endpoint service. | `string` | n/a | yes |
| vpc_id | VPC ID where the Network Load Balancer will be created. | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the Network Load Balancer. Must be in the same VPC and across multiple AZs for high availability. At least 1 subnet is required. | `list(string)` | n/a | yes |
| target_ip | IP address of the target resource (e.g., RDS endpoint IP, Redshift private IP). | `string` | n/a | yes |
| target_port | Port on the target resource. | `number` | n/a | yes |
| listener_port | NLB listener port. Defaults to target_port if not specified. | `number` | `null` | no |
| databricks_account_id | Databricks account ID. Used to construct the AWS account principal ARN that is authorized to connect to the VPC endpoint service. | `string` | n/a | yes |
| databricks_gov_shard | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. | `string` | `null` | no |
| aws_partition | AWS partition for ARN construction. Use "aws" for commercial; "aws-us-gov" for GovCloud (both civilian and DoD shards). | `string` | n/a | yes |
| tags | Tags applied to all AWS resources (NLB, target group, security group, VPC endpoint service). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| endpoint_service_name | VPC endpoint service name. Pass this to Databricks when configuring serverless PrivateLink. |
| endpoint_service_id | VPC endpoint service ID. |
| nlb_arn | ARN of the Network Load Balancer. |
| nlb_dns_name | DNS name of the Network Load Balancer. |
| target_group_arn | ARN of the target group. |
| security_group_id | ID of the security group attached to the NLB. |
| databricks_aws_account_id | Databricks control plane AWS account ID authorized to connect to the VPC endpoint service. Computed from databricks_gov_shard. Useful for verification. |

## Network Requirements

1. **Subnets**: Provide at least one subnet ID. For high availability, use multiple subnets across different availability zones.
2. **Target IP**: The IP address must be reachable from the NLB subnets. Ensure proper routing and security group rules on the target resource.
3. **Security Groups**: The target resource must allow inbound traffic from the NLB security group on the target port.

## Post-Deployment Steps

1. Note the `endpoint_service_name` output
2. Provide this value to Databricks when configuring serverless PrivateLink
3. Verify connectivity from Databricks serverless compute to your resource

## Examples

See the [examples](./examples) directory for complete usage examples:

- [basic](./examples/basic): Basic serverless PrivateLink setup

## Testing

This module includes automated tests:

```bash
# Run plan tests (no AWS credentials required)
terraform test

# Run integration tests (requires AWS credentials)
terraform test -filter=tests/integration.tftest.hcl
```

## Source Pattern

Based on the `aws-serverless-privatelink-to-cloud-service` pattern from [terraform-databricks-examples](https://github.com/databricks/terraform-databricks-examples).

## References

- [Databricks Serverless PrivateLink Documentation](https://docs.databricks.com/aws/en/administration/serverless-network-security/privatelink.html)
- [AWS VPC Endpoint Services](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html)
- [AWS Network Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html)

## License

See the root repository LICENSE file.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.49.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_security_group.nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service) | resource |
| [aws_vpc_endpoint_service_allowed_principal.databricks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service_allowed_principal) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition for ARN construction. Use "aws" for commercial; "aws-us-gov" for GovCloud (both civilian and DoD shards). | `string` | n/a | yes |
| <a name="input_databricks_account_id"></a> [databricks\_account\_id](#input\_databricks\_account\_id) | Databricks account ID. Used to construct the AWS account principal ARN that is authorized to connect to the VPC endpoint service. | `string` | n/a | yes |
| <a name="input_databricks_gov_shard"></a> [databricks\_gov\_shard](#input\_databricks\_gov\_shard) | Databricks GovCloud shard. null for commercial; "civilian" for AWS GovCloud civilian (FedRAMP High); "dod" for IL5/DoD. | `string` | `null` | no |
| <a name="input_listener_port"></a> [listener\_port](#input\_listener\_port) | NLB listener port. Defaults to target\_port if not specified. | `number` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Resource naming prefix. Used to name the NLB, target group, security group, and VPC endpoint service. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the Network Load Balancer. Must be in the same VPC and across multiple AZs for high availability. At least 1 subnet is required. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all AWS resources (NLB, target group, security group, VPC endpoint service). | `map(string)` | `{}` | no |
| <a name="input_target_ip"></a> [target\_ip](#input\_target\_ip) | IP address of the target resource (e.g., RDS endpoint IP, Redshift private IP). | `string` | n/a | yes |
| <a name="input_target_port"></a> [target\_port](#input\_target\_port) | Port on the target resource. | `number` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the Network Load Balancer will be created. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_databricks_aws_account_id"></a> [databricks\_aws\_account\_id](#output\_databricks\_aws\_account\_id) | Databricks control plane AWS account ID authorized to connect to the VPC endpoint service. Computed from databricks\_gov\_shard. Useful for verification. |
| <a name="output_endpoint_service_id"></a> [endpoint\_service\_id](#output\_endpoint\_service\_id) | VPC endpoint service ID. |
| <a name="output_endpoint_service_name"></a> [endpoint\_service\_name](#output\_endpoint\_service\_name) | VPC endpoint service name. Pass this to Databricks when configuring serverless PrivateLink. |
| <a name="output_nlb_arn"></a> [nlb\_arn](#output\_nlb\_arn) | ARN of the Network Load Balancer. |
| <a name="output_nlb_dns_name"></a> [nlb\_dns\_name](#output\_nlb\_dns\_name) | DNS name of the Network Load Balancer. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group attached to the NLB. |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | ARN of the target group. |
<!-- END_TF_DOCS -->