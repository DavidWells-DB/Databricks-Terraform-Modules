locals {
  # Build a map from firewall endpoint index → firewall endpoint ID.
  # The Network Firewall resource exposes firewall_status[0].sync_states, which is a
  # map keyed by AZ. We flatten it to a stable list ordered by subnet index so that
  # aws_route.private_nat can look up the right endpoint by position.
  #
  # sync_states is only populated after the firewall is created; during plan it is
  # empty. aws_route.private_nat uses tolist(aws_networkfirewall_firewall.this.firewall_status[0].sync_states)
  # directly in its count/for_each to avoid a pre-apply lookup error.
  firewall_endpoint_ids = [
    for s in tolist(aws_networkfirewall_firewall.this.firewall_status[0].sync_states) : s.attachment[0].endpoint_id
  ]

  # Stateful rule group references with priority — each ARN gets a distinct priority
  # so the policy is deterministic regardless of input order.
  stateful_rule_group_references = [
    for idx, arn in var.stateful_rule_group_arns : {
      resource_arn = arn
      priority     = (idx + 1) * 100
    }
  ]

  # Stateless rule group references with priority — same deterministic approach.
  stateless_rule_group_references = [
    for idx, arn in var.stateless_rule_group_arns : {
      resource_arn = arn
      priority     = (idx + 1) * 100
    }
  ]
}
