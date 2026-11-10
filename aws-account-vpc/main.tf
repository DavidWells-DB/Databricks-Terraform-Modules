# The pure AWS-side VPC for a Databricks classic workspace: VPC, compute subnets, route
# tables, and the Databricks-required security group. NO Databricks provider — the
# Databricks-side registration lives in dbx-account-mws-networks (the BYO-VPC entry point),
# and the one-call composition is aws-account-network-vpc (three-piece split, 2026-11-10).

# tfsec/checkov skips carried over from the pre-split module verbatim.
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
