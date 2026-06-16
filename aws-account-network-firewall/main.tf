# Firewall policy — references external rule group ARNs passed as inputs.
# The policy itself contains no inline rules; all filtering logic lives in
# rule groups created outside this module (passed via stateful/stateless_rule_group_arns).
resource "aws_networkfirewall_firewall_policy" "this" {
  name = "${var.firewall_name}-policy"

  firewall_policy {
    stateless_default_actions          = var.stateless_default_actions
    stateless_fragment_default_actions = var.stateless_fragment_default_actions

    dynamic "stateless_rule_group_reference" {
      for_each = local.stateless_rule_group_references

      content {
        resource_arn = stateless_rule_group_reference.value.resource_arn
        priority     = stateless_rule_group_reference.value.priority
      }
    }

    dynamic "stateful_rule_group_reference" {
      for_each = local.stateful_rule_group_references

      content {
        resource_arn = stateful_rule_group_reference.value.resource_arn
        priority     = stateful_rule_group_reference.value.priority
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.firewall_name}-policy"
  })

  #checkov:skip=CKV_AWS_346: CMK encryption for firewall policy is an operational security decision; callers can add encryption_configuration via the aws provider once a KMS key is available.
}

# Network Firewall — one endpoint is created per entry in firewall_subnet_ids.
# Each subnet should be in a distinct AZ for high availability.
resource "aws_networkfirewall_firewall" "this" {
  name                = var.firewall_name
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this.arn
  vpc_id              = var.vpc_id

  dynamic "subnet_mapping" {
    for_each = var.firewall_subnet_ids

    content {
      subnet_id = subnet_mapping.value
    }
  }

  # Firewall policy changes take effect immediately; no lifecycle protection needed.
  # delete_protection and subnet_change_protection default to false — intentional
  # so that callers can remove/resize without a manual CLI override.

  tags = merge(var.tags, {
    Name = var.firewall_name
  })

  #checkov:skip=CKV_AWS_344: delete_protection is caller-governed; enabling it here would block terraform destroy in development/test environments. Production callers should enable via the delete_protection argument.
  #checkov:skip=CKV_AWS_345: subnet_change_protection is caller-governed; enabling it here would block subnet updates in development environments.
  #checkov:skip=CKV2_AWS_63: Logging configuration is an operational concern managed separately; callers add aws_networkfirewall_logging_configuration to avoid coupling log destination to firewall creation.
}

# 0.0.0.0/0 route on each private route table → the matching firewall endpoint.
# Route tables are paired to firewall endpoints by index. If there are more route tables
# than firewall endpoints (e.g., 4 subnets, 2 firewall AZs), wrapping with modulo
# ensures every route table receives a route.
#
# NOTE: aws_networkfirewall_firewall.firewall_status is only fully populated after apply.
# During the first plan the sync_states set is empty, so count is 0 and no routes are
# planned. On the subsequent apply (after firewall creation) Terraform reconciles the
# routes. This is expected behavior for resources whose endpoint IDs aren't known until
# the firewall is READY.
resource "aws_route" "private_firewall" {
  count = length(var.private_route_table_ids)

  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoint_ids[count.index % length(local.firewall_endpoint_ids)]
}
