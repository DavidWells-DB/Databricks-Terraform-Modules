output "endpoint_service_name" {
  description = "VPC endpoint service name. Pass this to Databricks when configuring serverless PrivateLink."
  value       = aws_vpc_endpoint_service.this.service_name
}

output "endpoint_service_id" {
  description = "VPC endpoint service ID."
  value       = aws_vpc_endpoint_service.this.id
}

output "nlb_arn" {
  description = "ARN of the Network Load Balancer."
  value       = aws_lb.this.arn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer."
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group."
  value       = aws_lb_target_group.this.arn
}

output "security_group_id" {
  description = "ID of the security group attached to the NLB."
  value       = aws_security_group.nlb.id
}

output "databricks_aws_account_id" {
  description = "Databricks control plane AWS account ID authorized to connect to the VPC endpoint service. Computed from databricks_gov_shard. Useful for verification."
  value       = local.databricks_aws_account_id
}
