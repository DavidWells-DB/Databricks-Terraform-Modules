locals {
  # Databricks account host URL, derived from gov_shard, for documentation and output use.
  # The actual provider configuration (host =) lives in the root composition;
  # this local is exposed as an output to help callers validate their provider config.
  # Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud
  databricks_account_host = (
    var.databricks_gov_shard == "civilian" ? "https://accounts.cloud.databricks.us" :
    var.databricks_gov_shard == "dod" ? "https://accounts-dod.cloud.databricks.mil" :
    "https://accounts.cloud.databricks.com"
  )

  # Build per-subnet maps keyed by index for for_each stability.
  private_subnets = {
    for idx, cidr in var.private_subnet_cidrs :
    "${var.resource_prefix}-private-${idx}" => {
      cidr = cidr
      az   = var.azs[idx % length(var.azs)]
    }
  }

  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs :
    "${var.resource_prefix}-public-${idx}" => {
      cidr = cidr
      az   = var.azs[idx % length(var.azs)]
    }
  }

  privatelink_subnets = {
    for idx, cidr in var.privatelink_subnet_cidrs :
    "${var.resource_prefix}-pl-${idx}" => {
      cidr = cidr
      az   = var.azs[idx % length(var.azs)]
    }
  }

  # Build the vpc_endpoint_ids block only when both IDs are provided.
  # databricks_mws_networks accepts the nested block only when at least one ID is set.
  has_vpc_endpoints = (
    var.vpc_endpoint_ids != null &&
    (var.vpc_endpoint_ids.rest_api_id != null || var.vpc_endpoint_ids.relay_id != null)
  )
}
