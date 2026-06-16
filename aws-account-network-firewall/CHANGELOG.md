# Changelog

All notable changes to the `aws-account-network-firewall` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: creates `aws_networkfirewall_firewall` and `aws_networkfirewall_firewall_policy` with no inline rule groups.
- `aws_route` on each private route table pointing 0.0.0.0/0 to the per-AZ firewall endpoint (modulo-indexed for HA deployments).
- Inputs: `vpc_id`, `firewall_name`, `firewall_subnet_ids`, `private_route_table_ids`, `stateful_rule_group_arns`, `stateless_rule_group_arns`, `stateless_default_actions`, `stateless_fragment_default_actions`, `tags`.
- Variable validation on `vpc_id` (vpc- prefix format), `firewall_name` (1-128 chars, alphanumeric/hyphens), `firewall_subnet_ids` (subnet- prefix format), `private_route_table_ids` (rtb- prefix format), `stateless_default_actions` and `stateless_fragment_default_actions` (enumerated AWS values), and rule group ARN lists.
- Outputs: `firewall_id`, `firewall_arn`, `firewall_endpoint_ids`, `firewall_policy_arn`, `firewall_policy_id`, `firewall_status`.
- `locals.tf` with deterministic firewall endpoint ID extraction and priority-ordered rule group references.
- `examples/basic/` — minimum invocation with no rule groups for a commercial AWS account.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and key resource attribute checks.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).
