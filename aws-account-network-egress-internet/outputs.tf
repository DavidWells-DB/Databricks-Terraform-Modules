output "internet_gateway_id" {
  description = "ID of the Internet Gateway attached to the VPC."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs, in creation order. Pass individual entries to route-specific callers."
  value       = aws_nat_gateway.this[*].id
}

output "nat_public_ips" {
  description = "List of public Elastic IP addresses (one per NAT Gateway), in the same order as nat_gateway_ids. Use for firewall allowlisting at egress."
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_id" {
  description = "ID of the first (or sole) NAT Gateway. Convenience alias for nat_gateway_ids[0] when nat_gateway_count = 1."
  value       = aws_nat_gateway.this[0].id
}

output "nat_public_ip" {
  description = "Public Elastic IP of the first (or sole) NAT Gateway. Convenience alias for nat_public_ips[0] when nat_gateway_count = 1."
  value       = aws_eip.nat[0].public_ip
}
