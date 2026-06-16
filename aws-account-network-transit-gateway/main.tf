resource "aws_ec2_transit_gateway" "this" {
  description                     = "${var.resource_prefix} Transit Gateway"
  amazon_side_asn                 = var.tgw_asn
  dns_support                     = var.dns_support
  vpn_ecmp_support                = var.vpn_ecmp_support
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation

  tags = merge(local.common_tags, {
    Name = "${var.resource_prefix}-tgw"
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = var.vpc_attachments

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = each.value.vpc_id
  subnet_ids         = each.value.subnet_ids

  # Disable default route table association and propagation so that this module's
  # explicit route tables (below) remain authoritative. The Transit Gateway's
  # default route table is left unmodified and unused.
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(local.common_tags, {
    Name = "${var.resource_prefix}-tgw-attach-${each.key}"
  })
}

# One shared route table that all attachments associate to and propagate into.
# Callers needing per-attachment isolation should extend by calling this module
# once per segment — hub-and-spoke isolation is a root-composition concern.
resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = merge(local.common_tags, {
    Name = "${var.resource_prefix}-tgw-rt"
  })
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = aws_ec2_transit_gateway_vpc_attachment.this

  transit_gateway_attachment_id  = each.value.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = aws_ec2_transit_gateway_vpc_attachment.this

  transit_gateway_attachment_id  = each.value.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}
