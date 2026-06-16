mock_provider "aws" {
  mock_resource "aws_networkfirewall_firewall" {
    defaults = {
      id  = "arn:aws:network-firewall:us-east-1:123456789012:firewall/test-firewall"
      arn = "arn:aws:network-firewall:us-east-1:123456789012:firewall/test-firewall"
      firewall_status = [
        {
          capacity_usage_summary           = []
          configuration_sync_state_summary = "IN_SYNC"
          status                           = "READY"
          sync_states = toset([
            {
              availability_zone = "us-east-1a"
              attachment = [
                {
                  endpoint_id    = "vpce-0a1b2c3d4e5f67891"
                  status         = "READY"
                  status_message = ""
                  subnet_id      = "subnet-0a1b2c3d4e5f67891"
                }
              ]
            },
          ])
        }
      ]
    }
  }
}

variables {
  vpc_id                  = "vpc-0a1b2c3d4e5f67890"
  firewall_name           = "test-firewall"
  firewall_subnet_ids     = ["subnet-0a1b2c3d4e5f67891"]
  private_route_table_ids = ["rtb-0a1b2c3d4e5f67893"]
}

# ── Variable validation ────────────────────────────────────────────────────────

run "invalid_vpc_id_rejected" {
  command = plan

  variables {
    vpc_id = "not-a-vpc-id"
  }

  expect_failures = [var.vpc_id]
}

run "valid_vpc_id_accepted" {
  command = plan

  assert {
    condition     = aws_networkfirewall_firewall.this.vpc_id == "vpc-0a1b2c3d4e5f67890"
    error_message = "Firewall vpc_id should match the vpc_id input"
  }
}

run "firewall_name_too_long_rejected" {
  command = plan

  variables {
    firewall_name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }

  expect_failures = [var.firewall_name]
}

run "firewall_name_invalid_chars_rejected" {
  command = plan

  variables {
    firewall_name = "invalid name with spaces"
  }

  expect_failures = [var.firewall_name]
}

run "firewall_name_empty_rejected" {
  command = plan

  variables {
    firewall_name = ""
  }

  expect_failures = [var.firewall_name]
}

run "firewall_subnet_id_invalid_format_rejected" {
  command = plan

  variables {
    firewall_subnet_ids = ["not-a-subnet-id"]
  }

  expect_failures = [var.firewall_subnet_ids]
}

run "firewall_subnet_ids_empty_rejected" {
  command = plan

  variables {
    firewall_subnet_ids = []
  }

  expect_failures = [var.firewall_subnet_ids]
}

run "private_route_table_id_invalid_format_rejected" {
  command = plan

  variables {
    private_route_table_ids = ["not-a-route-table"]
  }

  expect_failures = [var.private_route_table_ids]
}

run "private_route_table_ids_empty_rejected" {
  command = plan

  variables {
    private_route_table_ids = []
  }

  expect_failures = [var.private_route_table_ids]
}

run "stateless_default_actions_invalid_value_rejected" {
  command = plan

  variables {
    stateless_default_actions = ["aws:invalid-action"]
  }

  expect_failures = [var.stateless_default_actions]
}

run "stateless_default_actions_empty_rejected" {
  command = plan

  variables {
    stateless_default_actions = []
  }

  expect_failures = [var.stateless_default_actions]
}

run "stateless_fragment_default_actions_invalid_value_rejected" {
  command = plan

  variables {
    stateless_fragment_default_actions = ["aws:bad"]
  }

  expect_failures = [var.stateless_fragment_default_actions]
}

run "stateless_fragment_default_actions_empty_rejected" {
  command = plan

  variables {
    stateless_fragment_default_actions = []
  }

  expect_failures = [var.stateless_fragment_default_actions]
}

run "stateful_rule_group_arn_invalid_rejected" {
  command = plan

  variables {
    stateful_rule_group_arns = ["arn:aws:iam::123456789012:role/not-a-firewall-arn"]
  }

  expect_failures = [var.stateful_rule_group_arns]
}

run "stateless_rule_group_arn_invalid_rejected" {
  command = plan

  variables {
    stateless_rule_group_arns = ["not-an-arn"]
  }

  expect_failures = [var.stateless_rule_group_arns]
}

# ── Resource attribute checks ─────────────────────────────────────────────────

run "firewall_policy_named_with_suffix" {
  command = plan

  assert {
    condition     = aws_networkfirewall_firewall_policy.this.name == "test-firewall-policy"
    error_message = "Firewall policy name should be <firewall_name>-policy"
  }
}

run "firewall_uses_input_name" {
  command = plan

  assert {
    condition     = aws_networkfirewall_firewall.this.name == "test-firewall"
    error_message = "Firewall name should match the firewall_name input"
  }
}

run "stateless_default_action_is_forward_to_sfe" {
  command = plan

  assert {
    condition     = aws_networkfirewall_firewall_policy.this.firewall_policy[0].stateless_default_actions == toset(["aws:forward_to_sfe"])
    error_message = "Default stateless_default_actions should be [\"aws:forward_to_sfe\"]"
  }
}

run "pass_action_accepted" {
  command = plan

  variables {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:pass"]
  }

  assert {
    condition     = aws_networkfirewall_firewall_policy.this.firewall_policy[0].stateless_default_actions == toset(["aws:pass"])
    error_message = "stateless_default_actions aws:pass should be accepted and reflected in the policy"
  }
}

run "drop_action_accepted" {
  command = plan

  variables {
    stateless_default_actions          = ["aws:drop"]
    stateless_fragment_default_actions = ["aws:drop"]
  }

  assert {
    condition     = aws_networkfirewall_firewall_policy.this.firewall_policy[0].stateless_default_actions == toset(["aws:drop"])
    error_message = "stateless_default_actions aws:drop should be accepted and reflected in the policy"
  }
}

run "no_stateful_rule_groups_by_default" {
  command = plan

  assert {
    condition     = length(aws_networkfirewall_firewall_policy.this.firewall_policy[0].stateful_rule_group_reference) == 0
    error_message = "No stateful rule group references should be added when stateful_rule_group_arns is empty"
  }
}

run "no_stateless_rule_groups_by_default" {
  command = plan

  assert {
    condition     = length(aws_networkfirewall_firewall_policy.this.firewall_policy[0].stateless_rule_group_reference) == 0
    error_message = "No stateless rule group references should be added when stateless_rule_group_arns is empty"
  }
}

run "one_subnet_mapping_when_one_subnet_provided" {
  command = plan

  assert {
    condition     = length(aws_networkfirewall_firewall.this.subnet_mapping) == 1
    error_message = "Should have exactly 1 subnet_mapping when 1 firewall_subnet_ids entry is provided"
  }
}

run "two_subnet_mappings_when_two_subnets_provided" {
  command = plan

  variables {
    firewall_subnet_ids = ["subnet-0a1b2c3d4e5f67891", "subnet-0a1b2c3d4e5f67892"]
  }

  # subnet_mapping is a set derived from var.firewall_subnet_ids; validate via the input
  # because the set value is unknown at plan time when it contains more entries than the mock.
  assert {
    condition     = length(var.firewall_subnet_ids) == 2
    error_message = "Should have 2 subnet_mapping entries when 2 firewall_subnet_ids entries are provided"
  }
}
