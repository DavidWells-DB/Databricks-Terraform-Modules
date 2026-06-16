output "s3_endpoint_id" {
  description = "ID of the S3 gateway VPC endpoint. Useful for referencing the endpoint in downstream route table or bucket policy configurations."
  value       = aws_vpc_endpoint.s3.id
}

output "s3_endpoint_arn" {
  description = "ARN of the S3 gateway VPC endpoint."
  value       = aws_vpc_endpoint.s3.arn
}

output "s3_cidr_blocks" {
  description = "CIDR blocks managed by the S3 gateway endpoint for use in security group rules or route tables."
  value       = aws_vpc_endpoint.s3.cidr_blocks
}

output "sts_endpoint_id" {
  description = "ID of the STS interface VPC endpoint."
  value       = aws_vpc_endpoint.sts.id
}

output "sts_endpoint_arn" {
  description = "ARN of the STS interface VPC endpoint."
  value       = aws_vpc_endpoint.sts.arn
}

output "sts_dns_entries" {
  description = "DNS entries for the STS interface endpoint. Each entry has dns_name and hosted_zone_id attributes."
  value       = aws_vpc_endpoint.sts.dns_entry
}

output "kinesis_endpoint_id" {
  description = "ID of the Kinesis Streams interface VPC endpoint."
  value       = aws_vpc_endpoint.kinesis.id
}

output "kinesis_endpoint_arn" {
  description = "ARN of the Kinesis Streams interface VPC endpoint."
  value       = aws_vpc_endpoint.kinesis.arn
}

output "kinesis_dns_entries" {
  description = "DNS entries for the Kinesis Streams interface endpoint. Each entry has dns_name and hosted_zone_id attributes."
  value       = aws_vpc_endpoint.kinesis.dns_entry
}

output "aws_partition" {
  description = "AWS partition computed from databricks_gov_shard. \"aws\" for commercial; \"aws-us-gov\" for GovCloud. Useful for verification and downstream ARN construction."
  value       = local.aws_partition
}
