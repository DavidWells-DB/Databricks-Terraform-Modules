locals {
  # Merge module-managed tags with caller-supplied tags. Module-managed tags
  # identify the resource_prefix so operators can filter by deployment.
  common_tags = merge(
    { Module = "aws-account-network-transit-gateway" },
    var.tags,
  )
}
