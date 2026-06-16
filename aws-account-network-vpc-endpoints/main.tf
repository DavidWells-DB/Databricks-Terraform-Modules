# S3 gateway endpoint — routes S3 traffic from private subnets directly to S3
# without traversing the internet or NAT gateway. Databricks requires S3 access
# for cluster logs, notebooks, and DBFS root storage.
#
# Endpoint policy: intentionally allows all S3 actions from any principal.
# The VPC gateway endpoint provides the network boundary — only traffic originating
# within this VPC can traverse it. Restricting to specific principals or resources
# would break Databricks access to user-owned S3 buckets and DBFS whose ARNs are
# unknown at module authoring time.
data "aws_iam_policy_document" "s3_endpoint" {
  #checkov:skip=CKV_AWS_108:VPC endpoint policy — network boundary is the VPC itself; unrestricted S3 access is required for DBFS and user-owned buckets
  #checkov:skip=CKV_AWS_109:VPC endpoint policy — resource wildcard required; customer bucket ARNs are unknown at module authoring time
  #checkov:skip=CKV_AWS_111:VPC endpoint policy — S3 write actions are required for DBFS, cluster logs, and notebook storage
  #checkov:skip=CKV_AWS_283:VPC endpoint policy — principal wildcard is correct; endpoint restricts by network path, not IAM principal
  #checkov:skip=CKV_AWS_356:VPC endpoint policy — resource wildcard required; customer bucket ARNs are unknown at module authoring time
  statement {
    sid    = "AllowAllS3ActionsFromVPC"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = local.s3_service_name
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids
  policy            = data.aws_iam_policy_document.s3_endpoint.json

  tags = merge(var.tags, {
    Name = "databricks-s3-endpoint"
  })
}

# STS interface endpoint — allows Databricks control plane and cluster nodes to
# call AWS STS (AssumeRole) without internet egress. Required for cross-account
# role assumption by the Databricks data plane.
#
# Endpoint policy: intentionally allows all STS actions from any principal.
# The interface endpoint's network scope restricts access to within the VPC.
# Databricks data plane nodes must assume cross-account roles whose ARNs are
# not known at module authoring time.
data "aws_iam_policy_document" "sts_endpoint" {
  #checkov:skip=CKV_AWS_107:VPC endpoint policy — STS credentials exposure check N/A; endpoint access is network-scoped to the VPC
  #checkov:skip=CKV_AWS_111:VPC endpoint policy — sts:AssumeRole write action is required; wildcard covers all data plane roles
  #checkov:skip=CKV_AWS_283:VPC endpoint policy — principal wildcard is correct; endpoint restricts by network path, not IAM principal
  #checkov:skip=CKV_AWS_356:VPC endpoint policy — resource wildcard required; role ARNs assumed by Databricks nodes are unknown at module authoring time
  statement {
    sid    = "AllowAllSTSActionsFromVPC"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["sts:*"]
    resources = ["*"]
  }
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = var.vpc_id
  service_name        = local.sts_service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.sts_endpoint.json

  tags = merge(var.tags, {
    Name = "databricks-sts-endpoint"
  })
}

# Kinesis interface endpoint — Databricks cluster log delivery uses Amazon Kinesis
# Data Streams. The endpoint keeps Kinesis API calls within the VPC.
#
# Endpoint policy: intentionally allows all Kinesis actions from any principal.
# The interface endpoint's network scope restricts access to within the VPC.
# Kinesis stream ARNs used by Databricks log delivery vary by region and account
# and are not known at module authoring time.
data "aws_iam_policy_document" "kinesis_endpoint" {
  #checkov:skip=CKV_AWS_111:VPC endpoint policy — Kinesis write actions are required for Databricks cluster log delivery
  #checkov:skip=CKV_AWS_283:VPC endpoint policy — principal wildcard is correct; endpoint restricts by network path, not IAM principal
  #checkov:skip=CKV_AWS_356:VPC endpoint policy — resource wildcard required; Kinesis stream ARNs used by Databricks are unknown at module authoring time
  statement {
    sid    = "AllowAllKinesisActionsFromVPC"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["kinesis:*"]
    resources = ["*"]
  }
}

resource "aws_vpc_endpoint" "kinesis" {
  vpc_id              = var.vpc_id
  service_name        = local.kinesis_service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.kinesis_endpoint.json

  tags = merge(var.tags, {
    Name = "databricks-kinesis-endpoint"
  })
}
