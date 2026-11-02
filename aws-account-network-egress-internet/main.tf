# Internet Gateway — one per VPC.
resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "igw"
  })
}

# Elastic IPs for NAT Gateways. domain = "vpc" is required by the AWS provider
# for EIPs that will be associated with NAT Gateways.
resource "aws_eip" "nat" {
  count = var.nat_gateway_count

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "nat-eip-${count.index + 1}"
  })

  # EIP must be created after the IGW so that the VPC has internet access
  # before the NAT gateway attempts to use it.
  depends_on = [aws_internet_gateway.this]
}

# NAT Gateways — placed in public subnets. Index wraps with modulo so that a
# caller can supply more NAT Gateways than public subnets if desired.
resource "aws_nat_gateway" "this" {
  count = var.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]

  tags = merge(var.tags, {
    Name = "nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

# E23 FIX (live-confirmed 2026-10-23, break_aws NET-08): the PUBLIC side needs its
# own default route. Public subnets ride the VPC MAIN route table, and no layer owned
# the 0.0.0.0/0 → IGW route on it — so the egress chain was structurally complete only
# to the NAT gateway and BLACKHOLED there: workspaces deployed RUNNING and every cluster
# died with BOOTSTRAP_TIMEOUT ("check network connectivity from the data plane to the
# control plane") while the NAT showed 'available'. This module owns the IGW, so it owns
# this route.
data "aws_route_table" "main" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_route" "public_igw" {
  route_table_id         = data.aws_route_table.main.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Default route on each private route table pointing 0.0.0.0/0 → NAT Gateway.
# Route tables are mapped to NAT Gateways with modulo so a single NAT Gateway
# can serve multiple route tables.
resource "aws_route" "private_nat" {
  count = length(var.private_route_table_ids)

  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index % var.nat_gateway_count].id
}
