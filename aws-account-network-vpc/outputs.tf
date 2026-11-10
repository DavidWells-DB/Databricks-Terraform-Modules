output "vpc_id" {
  description = "ID of the created VPC. Pass to downstream modules (e.g., aws-account-network-egress-internet, aws-account-network-vpc-endpoints) as their vpc_id input."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Map of private subnet name to subnet ID. Pass to aws-account-network-vpc-endpoints as its private_subnet_ids input."
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Map of public subnet name to subnet ID. Pass to aws-account-network-egress-internet as its public_subnet_ids input. Empty when no public_subnet_cidrs are configured."
  value       = module.vpc.public_subnet_ids
}

output "privatelink_subnet_ids" {
  description = "Map of PrivateLink subnet name to subnet ID. Pass to aws-account-network-privatelink-endpoints as its privatelink_subnet_ids input. Empty when no privatelink_subnet_cidrs are configured."
  value       = module.vpc.privatelink_subnet_ids
}

output "security_group_id" {
  description = "ID of the Databricks-required security group. Pass to aws-account-network-vpc-endpoints as its security_group_id input."
  value       = module.vpc.security_group_id
}

output "databricks_network_id" {
  description = "Databricks network configuration ID the workspace should use: the PrivateLink registration when vpc_endpoint_ids are set, otherwise the base registration. Pass to workspace creation modules as their network_id input."
  value       = module.registration.databricks_network_id
}

output "network_ids" {
  description = "Map of network config role (base / privatelink) to Databricks network ID. When PrivateLink is enabled both exist; the 'base' entry is the retained, now-detached config left behind by the in-place cutover. It is harmless (metadata-only, no documented account limit); delete it deliberately later if you want to tidy up — safe once no workspace references it."
  value       = module.registration.network_ids
}

output "private_route_table_ids" {
  description = "Map of private subnet name to route table ID. Pass to aws-account-network-egress-internet and aws-account-network-vpc-endpoints (S3 gateway) as their private_route_table_ids input."
  value       = module.vpc.private_route_table_ids
}

output "vpc_cidr" {
  description = "CIDR block of the VPC. Useful for constructing security group rules or firewall policies in downstream modules."
  value       = module.vpc.vpc_cidr
}

output "databricks_account_host" {
  description = "Databricks account host URL derived from databricks_gov_shard. Useful for root composition validation that the databricks.account provider is configured against the correct host."
  value       = local.databricks_account_host
}
