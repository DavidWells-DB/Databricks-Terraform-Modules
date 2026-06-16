output "peering_connection_id" {
  description = "ID of the AWS VPC peering connection. Pass to downstream route or security-group rules that reference the peering link."
  value       = aws_vpc_peering_connection.this.id
}

output "peering_connection_status" {
  description = "Status of the VPC peering connection after acceptance (e.g., 'active'). Useful for verifying the connection is healthy."
  value       = aws_vpc_peering_connection_accepter.this.accept_status
}

output "requester_route_ids" {
  description = "Map of requester route table ID to the Terraform resource ID of the route added for the accepter CIDR. Useful for debugging and dependency chaining."
  value       = { for rt_id, r in aws_route.requester_to_accepter : rt_id => r.id }
}

output "accepter_route_ids" {
  description = "Map of accepter route table ID to the Terraform resource ID of the route added for the requester CIDR. Useful for debugging and dependency chaining."
  value       = { for rt_id, r in aws_route.accepter_to_requester : rt_id => r.id }
}
