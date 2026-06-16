output "firewall_id" {
  description = "ID of the AWS Network Firewall resource."
  value       = aws_networkfirewall_firewall.this.id
}

output "firewall_arn" {
  description = "ARN of the AWS Network Firewall. Use for IAM policies and CloudWatch log delivery configuration."
  value       = aws_networkfirewall_firewall.this.arn
}

output "firewall_endpoint_ids" {
  description = "List of VPC endpoint IDs for the Network Firewall endpoints, one per firewall subnet. Route tables point to these endpoints."
  value       = local.firewall_endpoint_ids
}

output "firewall_policy_arn" {
  description = "ARN of the Network Firewall policy associated with the firewall. Useful for attaching additional rule groups post-creation."
  value       = aws_networkfirewall_firewall_policy.this.arn
}

output "firewall_policy_id" {
  description = "ID of the Network Firewall policy."
  value       = aws_networkfirewall_firewall_policy.this.id
}

output "firewall_status" {
  description = "Full firewall_status block from the aws_networkfirewall_firewall resource. Contains sync_states per AZ with endpoint attachment details."
  value       = aws_networkfirewall_firewall.this.firewall_status
}
