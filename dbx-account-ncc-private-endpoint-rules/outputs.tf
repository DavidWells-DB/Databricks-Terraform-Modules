output "rule_ids" {
  value       = { for k, r in databricks_mws_ncc_private_endpoint_rule.this : k => r.id }
  description = "Private endpoint rule IDs keyed by the caller's stable keys."
}
