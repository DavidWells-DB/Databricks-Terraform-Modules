mock_provider "aws" {}

variables {
  name                  = "test-serverless-pl"
  vpc_id                = "vpc-0123456789abcdef0"
  subnet_ids            = ["subnet-0123456789abcdef0"]
  target_ip             = "10.0.1.100"
  target_port           = 5432
  databricks_account_id = "00000000-0000-0000-0000-000000000000"
  aws_partition         = "aws"
  databricks_gov_shard  = null
}

run "commercial_shard_uses_commercial_account_id" {
  command = plan

  assert {
    condition     = output.databricks_aws_account_id == "414351767826"
    error_message = "Commercial shard should resolve to Databricks AWS account ID 414351767826"
  }
}

run "civilian_shard_uses_civilian_account_id" {
  command = plan

  variables {
    aws_partition        = "aws-us-gov"
    databricks_gov_shard = "civilian"
  }

  assert {
    condition     = output.databricks_aws_account_id == "044793339203"
    error_message = "GovCloud civilian shard should resolve to Databricks AWS account ID 044793339203"
  }
}

run "dod_shard_uses_dod_account_id" {
  command = plan

  variables {
    aws_partition        = "aws-us-gov"
    databricks_gov_shard = "dod"
  }

  assert {
    condition     = output.databricks_aws_account_id == "170661010020"
    error_message = "GovCloud DoD shard should resolve to Databricks AWS account ID 170661010020"
  }
}

run "invalid_aws_partition_rejected" {
  command = plan

  variables {
    aws_partition = "invalid-partition"
  }

  expect_failures = [var.aws_partition]
}

run "invalid_gov_shard_rejected" {
  command = plan

  variables {
    databricks_gov_shard = "invalid-shard"
  }

  expect_failures = [var.databricks_gov_shard]
}

run "nlb_uses_network_type" {
  command = plan

  assert {
    condition     = aws_lb.this.load_balancer_type == "network"
    error_message = "Load balancer type should be network"
  }
}

run "nlb_is_internal" {
  command = plan

  assert {
    condition     = aws_lb.this.internal == true
    error_message = "Load balancer should be internal"
  }
}

run "target_group_uses_tcp_protocol" {
  command = plan

  assert {
    condition     = aws_lb_target_group.this.protocol == "TCP"
    error_message = "Target group protocol should be TCP"
  }
}

run "target_group_uses_ip_target_type" {
  command = plan

  assert {
    condition     = aws_lb_target_group.this.target_type == "ip"
    error_message = "Target group target_type should be ip"
  }
}

run "listener_uses_target_port_by_default" {
  command = plan

  assert {
    condition     = aws_lb_listener.this.port == var.target_port
    error_message = "Listener port should default to target_port"
  }
}

run "listener_uses_custom_port_when_specified" {
  command = plan

  variables {
    listener_port = 8080
  }

  assert {
    condition     = aws_lb_listener.this.port == 8080
    error_message = "Listener port should use listener_port when specified"
  }
}

run "endpoint_service_accepts_connections_automatically" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint_service.this.acceptance_required == false
    error_message = "VPC endpoint service should not require manual acceptance"
  }
}

run "security_group_egress_targets_resource_ip" {
  command = plan

  assert {
    condition     = length([for rule in aws_security_group.nlb.egress : rule if rule.cidr_blocks[0] == "10.0.1.100/32"]) == 1
    error_message = "Security group should have egress rule targeting the target resource IP"
  }
}

run "name_too_long_rejected" {
  command = plan

  variables {
    name = "this-name-is-way-too-long-for-aws-resource-naming"
  }

  expect_failures = [var.name]
}

run "invalid_vpc_id_rejected" {
  command = plan

  variables {
    vpc_id = "invalid-vpc-id"
  }

  expect_failures = [var.vpc_id]
}

run "empty_subnet_list_rejected" {
  command = plan

  variables {
    subnet_ids = []
  }

  expect_failures = [var.subnet_ids]
}

run "invalid_subnet_id_rejected" {
  command = plan

  variables {
    subnet_ids = ["invalid-subnet-id"]
  }

  expect_failures = [var.subnet_ids]
}

run "invalid_target_ip_rejected" {
  command = plan

  variables {
    target_ip = "not-an-ip-address"
  }

  expect_failures = [var.target_ip]
}

run "target_port_below_range_rejected" {
  command = plan

  variables {
    target_port = 0
  }

  expect_failures = [var.target_port]
}

run "target_port_above_range_rejected" {
  command = plan

  variables {
    target_port = 65536
  }

  expect_failures = [var.target_port]
}

run "listener_port_below_range_rejected" {
  command = plan

  variables {
    listener_port = 0
  }

  expect_failures = [var.listener_port]
}

run "listener_port_above_range_rejected" {
  command = plan

  variables {
    listener_port = 65536
  }

  expect_failures = [var.listener_port]
}
