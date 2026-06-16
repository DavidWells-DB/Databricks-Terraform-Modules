locals {
  # AWS partition for endpoint policy ARN construction.
  # GovCloud (both shards) uses aws-us-gov; commercial uses aws.
  aws_partition = var.databricks_gov_shard != null ? "aws-us-gov" : "aws"

  # Endpoint service names are region-scoped for interface endpoints;
  # gateway endpoints use a fixed service name that is region-independent.
  s3_service_name      = "com.amazonaws.${var.region}.s3"
  sts_service_name     = "com.amazonaws.${var.region}.sts"
  kinesis_service_name = "com.amazonaws.${var.region}.kinesis-streams"
}
