resource "aws_vpc" "this" { #tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = var.resource_prefix
  })

  #checkov:skip=CKV2_AWS_11: VPC flow log delivery is an operational concern managed by a separate module.
  #checkov:skip=CKV2_AWS_12: Default SG hardening is an account-level baseline not in this module's scope.
}

# Private subnets — used by Databricks compute (driver + worker nodes).
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = each.key
  })
}

# Public subnets — optional; used for NAT gateways or internet-facing load balancers.
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = each.key
  })
}

# PrivateLink-dedicated subnets — optional; used by aws-account-network-privatelink-endpoints.
resource "aws_subnet" "privatelink" {
  for_each = local.privatelink_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = each.key
  })
}

# One route table per private subnet — required so aws-account-network-egress-internet
# can add a 0.0.0.0/0 → NAT gateway route per AZ without affecting other subnets.
resource "aws_route_table" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${each.key}-rt"
  })
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# Databricks-required security group.
# Rules are exactly as specified in:
# https://docs.databricks.com/aws/en/security/network/classic/security-group
resource "aws_security_group" "this" {
  name        = "${var.resource_prefix}-databricks"
  description = "Databricks workspace compute security group - allows all internal VPC traffic and all egress."
  vpc_id      = aws_vpc.this.id

  # Inbound: all traffic from the same security group (node-to-node communication).
  ingress {
    description = "Allow all traffic within the Databricks security group (cluster node to node)."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Outbound: all egress - Databricks requires unrestricted egress by default.
  # Open egress is a Databricks requirement per the URL above.
  # Customers restricting egress should use aws-account-network-firewall instead.
  egress {
    description = "Allow all egress - Databricks control plane connectivity and package installation."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
  }

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-databricks"
  })

  #checkov:skip=CKV_AWS_382: Open egress is a Databricks requirement per https://docs.databricks.com/aws/en/security/network/classic/security-group
  #checkov:skip=CKV2_AWS_5: This SG is attached to Databricks-managed EC2 instances; attachment is outside Terraform's scope here.
}

# Register the VPC configuration(s) with the Databricks account API.
# Pairs the cloud-side VPC with its Databricks-side registration per DATABRICKS_RULES.md Rule 1.4.
#
# Keyed by role (see locals.network_configs): always a "base" config; a separate "privatelink"
# config is ADDED when vpc_endpoint_ids are supplied. Adding PrivateLink to a running workspace
# therefore creates the new "privatelink" registration and RETAINS "base" (the caller repoints
# the workspace's network_id in place). No create_before_destroy and no replacement: nothing is
# deleted while attached, so the delete-while-attached failure cannot occur. Both configs may
# reference the same subnets — Databricks explicitly allows multiple network config objects on
# the same VPC/subnets (docs: customer-managed VPC, "share one subnet across multiple workspaces").
resource "databricks_mws_networks" "this" {
  for_each = local.network_configs

  provider           = databricks.account
  account_id         = var.databricks_account_id
  network_name       = each.value
  security_group_ids = [aws_security_group.this.id]
  subnet_ids         = [for k, s in aws_subnet.private : s.id]
  vpc_id             = aws_vpc.this.id

  dynamic "vpc_endpoints" {
    # PrivateLink endpoint IDs belong only to the "privatelink" registration (and only when
    # supplied; enable_privatelink may be set a plan before the endpoint IDs are known).
    for_each = each.key == "privatelink" && var.vpc_endpoint_ids != null ? [var.vpc_endpoint_ids] : []

    content {
      dataplane_relay = vpc_endpoints.value.relay_id != null ? [vpc_endpoints.value.relay_id] : []
      rest_api        = vpc_endpoints.value.rest_api_id != null ? [vpc_endpoints.value.rest_api_id] : []
    }
  }
}

# Migrate pre-v0.3.0 state (single unkeyed registration) to the "base" key with no destroy/create.
moved {
  from = databricks_mws_networks.this
  to   = databricks_mws_networks.this["base"]
}
