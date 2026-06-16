# Initiate the VPC peering connection from the requester side.
# For cross-account peering the accepter must exist in a different account;
# auto_accept is always false — acceptance is handled by aws_vpc_peering_connection_accepter.
resource "aws_vpc_peering_connection" "this" {
  vpc_id        = var.requester_vpc_id
  peer_vpc_id   = var.accepter_vpc_id
  peer_owner_id = var.accepter_account_id
  peer_region   = var.accepter_region
  auto_accept   = false

  tags = local.common_tags
}

# Accept the peering connection on the accepter side.
# For cross-account peering the aws provider must be configured for the accepter account.
# For same-account peering the default provider serves both sides.
resource "aws_vpc_peering_connection_accepter" "this" {
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true

  tags = local.common_tags
}

# Routes in the requester VPC pointing to the accepter VPC's CIDR.
# for_each is used because each route table has a distinct identity.
resource "aws_route" "requester_to_accepter" {
  for_each = toset(var.requester_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id
}

# Routes in the accepter VPC pointing back to the requester VPC's CIDR.
resource "aws_route" "accepter_to_requester" {
  for_each = toset(var.accepter_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id
}
