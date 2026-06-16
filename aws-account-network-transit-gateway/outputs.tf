output "transit_gateway_id" {
  description = "ID of the Transit Gateway. Pass to VPC route resources or other network modules that need to forward traffic through this TGW."
  value       = aws_ec2_transit_gateway.this.id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway. Useful for RAM (Resource Access Manager) sharing across AWS accounts."
  value       = aws_ec2_transit_gateway.this.arn
}

output "transit_gateway_owner_id" {
  description = "AWS account ID that owns the Transit Gateway."
  value       = aws_ec2_transit_gateway.this.owner_id
}

output "attachment_ids" {
  description = "Map of attachment name to Transit Gateway VPC attachment ID. Keys match the keys in var.vpc_attachments."
  value       = { for k, v in aws_ec2_transit_gateway_vpc_attachment.this : k => v.id }
}

output "route_table_id" {
  description = "ID of the Transit Gateway route table shared by all VPC attachments. Use this when adding static routes from the root composition."
  value       = aws_ec2_transit_gateway_route_table.this.id
}

output "route_table_ids" {
  description = "Map containing the single route table ID keyed by \"shared\". Provided for compatibility with callers that expect a map. For most callers, route_table_id is sufficient."
  value       = { shared = aws_ec2_transit_gateway_route_table.this.id }
}
