output "vpc_id" {
  description = "ID of the created VPC. Pass to downstream modules (e.g., aws-account-network-egress-internet, aws-account-network-vpc-endpoints) as their vpc_id input."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Map of private subnet name to subnet ID. Pass to aws-account-network-vpc-endpoints as its private_subnet_ids input."
  value       = { for k, s in aws_subnet.private : k => s.id }
}

output "public_subnet_ids" {
  description = "Map of public subnet name to subnet ID. Pass to aws-account-network-egress-internet as its public_subnet_ids input. Empty when no public_subnet_cidrs are configured."
  value       = { for k, s in aws_subnet.public : k => s.id }
}

output "privatelink_subnet_ids" {
  description = "Map of PrivateLink subnet name to subnet ID. Pass to aws-account-network-privatelink-endpoints as its privatelink_subnet_ids input. Empty when no privatelink_subnet_cidrs are configured."
  value       = { for k, s in aws_subnet.privatelink : k => s.id }
}

output "security_group_id" {
  description = "ID of the Databricks-required security group. Pass to aws-account-network-vpc-endpoints as its security_group_id input."
  value       = aws_security_group.this.id
}

output "databricks_network_id" {
  description = "Databricks network configuration ID from databricks_mws_networks. Pass to workspace creation modules as their network_id input."
  value       = databricks_mws_networks.this.network_id
}

output "private_route_table_ids" {
  description = "Map of private subnet name to route table ID. Pass to aws-account-network-egress-internet and aws-account-network-vpc-endpoints (S3 gateway) as their private_route_table_ids input."
  value       = { for k, rt in aws_route_table.private : k => rt.id }
}

output "vpc_cidr" {
  description = "CIDR block of the VPC. Useful for constructing security group rules or firewall policies in downstream modules."
  value       = aws_vpc.this.cidr_block
}

output "databricks_account_host" {
  description = "Databricks account host URL derived from databricks_gov_shard. Useful for root composition validation that the databricks.account provider is configured against the correct host."
  value       = local.databricks_account_host
}
