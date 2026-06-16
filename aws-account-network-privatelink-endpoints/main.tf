# Security group for the PrivateLink interface endpoints.
# Opens ports required for Databricks PrivateLink connectivity:
#   443  — HTTPS REST API and workspace access
#   2443 — FIPS-compliant HTTPS used by the Compliance Security Profile
#   6666 — SCC relay (Secure Cluster Connectivity)
resource "aws_security_group" "this" { #checkov:skip=CKV_AWS_382: VPC endpoint ENIs require unrestricted egress; traffic stays within AWS PrivateLink
  name        = var.security_group_name
  description = "Controls inbound and outbound traffic to Databricks PrivateLink interface endpoints."
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS to Databricks workspace REST API endpoint"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.security_group_ingress_cidr_blocks
  }

  ingress {
    description = "FIPS HTTPS - Compliance Security Profile requirement"
    from_port   = 2443
    to_port     = 2443
    protocol    = "tcp"
    cidr_blocks = var.security_group_ingress_cidr_blocks
  }

  ingress {
    description = "SCC relay (Secure Cluster Connectivity) traffic"
    from_port   = 6666
    to_port     = 6666
    protocol    = "tcp"
    cidr_blocks = var.security_group_ingress_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic from the PrivateLink endpoint ENIs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr -- VPC endpoint ENIs require unrestricted egress; traffic stays within AWS PrivateLink
  }

  tags = merge(var.tags, {
    Name = var.security_group_name
  })
}

# ---------------------------------------------------------------------------
# AWS VPC Endpoints (interface type) — Databricks PrivateLink
# ---------------------------------------------------------------------------

# Workspace (REST API) endpoint: routes Databricks workspace REST API traffic
# from within the VPC to the Databricks control plane without traversing the
# public internet.
resource "aws_vpc_endpoint" "workspace" {
  vpc_id              = var.vpc_id
  service_name        = local.workspace_service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.privatelink_subnet_ids
  security_group_ids  = [aws_security_group.this.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.workspace_vpc_endpoint_name}-aws"
  })
}

# SCC relay endpoint: routes Secure Cluster Connectivity (SCC) relay traffic
# from cluster nodes back to the Databricks control plane.
resource "aws_vpc_endpoint" "relay" {
  vpc_id              = var.vpc_id
  service_name        = local.relay_service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.privatelink_subnet_ids
  security_group_ids  = [aws_security_group.this.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.relay_vpc_endpoint_name}-aws"
  })
}

# Service-direct (frontend) endpoint: optional third endpoint for workspaces
# that require fully private front-end access. Not available in GovCloud shards.
# Only created when enable_service_direct = true.
resource "aws_vpc_endpoint" "service_direct" {
  count = var.enable_service_direct ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = local.service_direct_service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.privatelink_subnet_ids
  security_group_ids  = [aws_security_group.this.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.service_direct_vpc_endpoint_name}-aws"
  })
}

# ---------------------------------------------------------------------------
# Databricks MWS VPC Endpoint registrations
# Each AWS VPC endpoint must be registered with the Databricks account API
# before it can be referenced in network configurations or private access settings.
# ---------------------------------------------------------------------------

resource "databricks_mws_vpc_endpoint" "workspace" {
  provider = databricks.account

  # account_id is set in the provider block (databricks.account); specifying it
  # at resource level is deprecated in provider >= 1.60.
  vpc_endpoint_name   = var.workspace_vpc_endpoint_name
  aws_vpc_endpoint_id = aws_vpc_endpoint.workspace.id
  region              = var.region
}

resource "databricks_mws_vpc_endpoint" "relay" {
  provider = databricks.account

  vpc_endpoint_name   = var.relay_vpc_endpoint_name
  aws_vpc_endpoint_id = aws_vpc_endpoint.relay.id
  region              = var.region
}

resource "databricks_mws_vpc_endpoint" "service_direct" {
  count    = var.enable_service_direct ? 1 : 0
  provider = databricks.account

  vpc_endpoint_name   = var.service_direct_vpc_endpoint_name
  aws_vpc_endpoint_id = aws_vpc_endpoint.service_direct[0].id
  region              = var.region
}

# ---------------------------------------------------------------------------
# Private Access Settings
# Defines which VPC endpoints may access workspaces in this region, and
# whether public access remains enabled alongside PrivateLink.
# ---------------------------------------------------------------------------

resource "databricks_mws_private_access_settings" "this" {
  provider = databricks.account

  # account_id is set in the provider block (databricks.account); specifying it
  # at resource level is deprecated in provider >= 1.60.
  private_access_settings_name = var.private_access_settings_name
  region                       = var.region
  public_access_enabled        = var.public_access_enabled
  private_access_level         = var.private_access_level

  # allowed_vpc_endpoint_ids is only meaningful when private_access_level = "ENDPOINT".
  # When private_access_level = "ACCOUNT", the field is ignored by the API.
  allowed_vpc_endpoint_ids = var.private_access_level == "ENDPOINT" ? var.allowed_vpc_endpoint_ids : []
}
