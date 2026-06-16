terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    aws = {
      # 5.0+: aws_networkfirewall_firewall, aws_networkfirewall_firewall_policy, and
      # aws_networkfirewall_rule_group are stable in the 5.x provider.
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
