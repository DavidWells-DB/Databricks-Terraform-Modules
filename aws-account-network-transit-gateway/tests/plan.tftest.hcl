mock_provider "aws" {}

variables {
  resource_prefix = "test"
  tgw_asn         = 64512
  vpc_attachments = {
    workspace = {
      vpc_id     = "vpc-0000000000000001"
      subnet_ids = ["subnet-0000000000000001", "subnet-0000000000000002"]
    }
    shared-services = {
      vpc_id     = "vpc-0000000000000002"
      subnet_ids = ["subnet-0000000000000003"]
    }
  }
}

# ── Resource attribute checks ────────────────────────────────────────────────

run "transit_gateway_name_uses_prefix" {
  command = plan

  assert {
    condition     = aws_ec2_transit_gateway.this.tags["Name"] == "test-tgw"
    error_message = "Transit Gateway Name tag should be <resource_prefix>-tgw"
  }
}

run "transit_gateway_asn_matches_input" {
  command = plan

  assert {
    condition     = aws_ec2_transit_gateway.this.amazon_side_asn == 64512
    error_message = "Transit Gateway ASN should match tgw_asn input"
  }
}

run "transit_gateway_default_settings" {
  command = plan

  assert {
    condition     = aws_ec2_transit_gateway.this.dns_support == "enable"
    error_message = "dns_support default should be 'enable'"
  }

  assert {
    condition     = aws_ec2_transit_gateway.this.vpn_ecmp_support == "enable"
    error_message = "vpn_ecmp_support default should be 'enable'"
  }

  assert {
    condition     = aws_ec2_transit_gateway.this.default_route_table_association == "disable"
    error_message = "default_route_table_association default should be 'disable'"
  }

  assert {
    condition     = aws_ec2_transit_gateway.this.default_route_table_propagation == "disable"
    error_message = "default_route_table_propagation default should be 'disable'"
  }
}

run "attachment_names_use_prefix_and_key" {
  command = plan

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["workspace"].tags["Name"] == "test-tgw-attach-workspace"
    error_message = "VPC attachment Name tag should be <resource_prefix>-tgw-attach-<key>"
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["shared-services"].tags["Name"] == "test-tgw-attach-shared-services"
    error_message = "VPC attachment Name tag should be <resource_prefix>-tgw-attach-<key>"
  }
}

run "route_table_name_uses_prefix" {
  command = plan

  assert {
    condition     = aws_ec2_transit_gateway_route_table.this.tags["Name"] == "test-tgw-rt"
    error_message = "Route table Name tag should be <resource_prefix>-tgw-rt"
  }
}

# ── Variable validation: resource_prefix ────────────────────────────────────

run "resource_prefix_empty_rejected" {
  command = plan

  variables {
    resource_prefix = ""
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_too_long_rejected" {
  command = plan

  variables {
    resource_prefix = "this-prefix-is-way-too-long-for-the-module"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_invalid_chars_rejected" {
  command = plan

  variables {
    resource_prefix = "invalid prefix with spaces"
  }

  expect_failures = [var.resource_prefix]
}

# ── Variable validation: tgw_asn ────────────────────────────────────────────

run "tgw_asn_below_private_range_rejected" {
  command = plan

  variables {
    tgw_asn = 1000
  }

  expect_failures = [var.tgw_asn]
}

run "tgw_asn_public_range_rejected" {
  command = plan

  variables {
    tgw_asn = 65535
  }

  expect_failures = [var.tgw_asn]
}

run "tgw_asn_valid_32bit_accepted" {
  command = plan

  variables {
    tgw_asn = 4200000000
  }

  assert {
    condition     = aws_ec2_transit_gateway.this.amazon_side_asn == 4200000000
    error_message = "32-bit private ASN 4200000000 should be accepted"
  }
}

# ── Variable validation: dns_support ────────────────────────────────────────

run "dns_support_invalid_value_rejected" {
  command = plan

  variables {
    dns_support = "yes"
  }

  expect_failures = [var.dns_support]
}

# ── Variable validation: vpn_ecmp_support ───────────────────────────────────

run "vpn_ecmp_support_invalid_value_rejected" {
  command = plan

  variables {
    vpn_ecmp_support = "true"
  }

  expect_failures = [var.vpn_ecmp_support]
}

# ── Variable validation: default_route_table_association ────────────────────

run "default_route_table_association_invalid_rejected" {
  command = plan

  variables {
    default_route_table_association = "on"
  }

  expect_failures = [var.default_route_table_association]
}

# ── Variable validation: default_route_table_propagation ────────────────────

run "default_route_table_propagation_invalid_rejected" {
  command = plan

  variables {
    default_route_table_propagation = "off"
  }

  expect_failures = [var.default_route_table_propagation]
}

# ── Variable validation: vpc_attachments ────────────────────────────────────

run "vpc_attachment_empty_subnets_rejected" {
  command = plan

  variables {
    vpc_attachments = {
      workspace = {
        vpc_id     = "vpc-0000000000000001"
        subnet_ids = []
      }
    }
  }

  expect_failures = [var.vpc_attachments]
}
