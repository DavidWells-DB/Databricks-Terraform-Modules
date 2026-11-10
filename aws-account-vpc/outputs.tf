output "vpc_id" {
  description = "ID of the created VPC. Pass to dbx-account-mws-networks (registration) or aws-account-network-egress-internet / aws-account-network-vpc-endpoints as their vpc_id input."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Map of private subnet name to subnet ID. Pass to dbx-account-mws-networks (registration) or aws-account-network-vpc-endpoints."
  value       = { for k, s in aws_subnet.private : k => s.id }
}

output "public_subnet_ids" {
  description = "Map of public subnet name to subnet ID. Pass to aws-account-network-egress-internet. Empty when no public_subnet_cidrs are configured."
  value       = { for k, s in aws_subnet.public : k => s.id }
}

output "privatelink_subnet_ids" {
  description = "Map of PrivateLink subnet name to subnet ID. Pass to aws-account-network-privatelink-endpoints. Empty when no privatelink_subnet_cidrs are configured."
  value       = { for k, s in aws_subnet.privatelink : k => s.id }
}

output "security_group_id" {
  description = "ID of the Databricks-required security group. Pass to dbx-account-mws-networks (registration)."
  value       = aws_security_group.this.id
}

output "private_route_table_ids" {
  description = "Map of private subnet name to route table ID. Pass to aws-account-network-egress-internet and aws-account-network-vpc-endpoints (S3 gateway)."
  value       = { for k, rt in aws_route_table.private : k => rt.id }
}

output "vpc_cidr" {
  description = "CIDR block of the VPC. Useful for constructing security group rules or firewall policies in downstream modules."
  value       = aws_vpc.this.cidr_block
}
