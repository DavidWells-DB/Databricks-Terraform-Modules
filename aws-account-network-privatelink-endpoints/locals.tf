locals {
  # ---------------------------------------------------------------------------
  # Databricks PrivateLink endpoint service attachment URIs by region.
  #
  # Source: https://docs.databricks.com/aws/en/resources/ip-domain-region
  # GovCloud entries use us-gov-west-1; both civilian and dod shards share the
  # same AWS region but have distinct service attachment URIs.
  #
  # Format: com.amazonaws.vpce.<region>.vpce-svc-<id>
  # ---------------------------------------------------------------------------

  # Workspace (REST API) endpoint service attachment URIs — commercial regions.
  _workspace_service_names_commercial = {
    "ap-northeast-1" = "com.amazonaws.vpce.ap-northeast-1.vpce-svc-02691fd610d24fd64"
    "ap-northeast-2" = "com.amazonaws.vpce.ap-northeast-2.vpce-svc-0babb9bde64f34d7e"
    "ap-south-1"     = "com.amazonaws.vpce.ap-south-1.vpce-svc-0dbfe5d9ee18d6411"
    "ap-southeast-1" = "com.amazonaws.vpce.ap-southeast-1.vpce-svc-02535b257fc253ff4"
    "ap-southeast-2" = "com.amazonaws.vpce.ap-southeast-2.vpce-svc-0b87155ddd6954974"
    "ap-southeast-3" = "com.amazonaws.vpce.ap-southeast-3.vpce-svc-0fec4092997affd53"
    "ca-central-1"   = "com.amazonaws.vpce.ca-central-1.vpce-svc-0205f197ec0e28d65"
    "eu-central-1"   = "com.amazonaws.vpce.eu-central-1.vpce-svc-081f78503812597f7"
    "eu-west-1"      = "com.amazonaws.vpce.eu-west-1.vpce-svc-0da6ebf1461278016"
    "eu-west-2"      = "com.amazonaws.vpce.eu-west-2.vpce-svc-01148c7cdc1d1326c"
    "eu-west-3"      = "com.amazonaws.vpce.eu-west-3.vpce-svc-008b9368d1d011f37"
    "sa-east-1"      = "com.amazonaws.vpce.sa-east-1.vpce-svc-0bafcea8cdfe11b66"
    "us-east-1"      = "com.amazonaws.vpce.us-east-1.vpce-svc-09143d1e626de2f04"
    "us-east-2"      = "com.amazonaws.vpce.us-east-2.vpce-svc-041dc2b4d7796b8d3"
    "us-west-1"      = "com.amazonaws.vpce.us-west-1.vpce-svc-09bb6ca26208063f2"
    "us-west-2"      = "com.amazonaws.vpce.us-west-2.vpce-svc-0129f463fcfbc46c5"
  }

  # SCC relay endpoint service attachment URIs — commercial regions.
  _relay_service_names_commercial = {
    "ap-northeast-1" = "com.amazonaws.vpce.ap-northeast-1.vpce-svc-02aa633bda3edbec0"
    "ap-northeast-2" = "com.amazonaws.vpce.ap-northeast-2.vpce-svc-0dc0e98a5800db5c4"
    "ap-south-1"     = "com.amazonaws.vpce.ap-south-1.vpce-svc-03fd4d9b61414f3de"
    "ap-southeast-1" = "com.amazonaws.vpce.ap-southeast-1.vpce-svc-0557367c6fc1a0c5c"
    "ap-southeast-2" = "com.amazonaws.vpce.ap-southeast-2.vpce-svc-0b4a72e8f825495f6"
    "ap-southeast-3" = "com.amazonaws.vpce.ap-southeast-3.vpce-svc-025ca447c232c6a1b"
    "ca-central-1"   = "com.amazonaws.vpce.ca-central-1.vpce-svc-0c4e25bdbcbfbb684"
    "eu-central-1"   = "com.amazonaws.vpce.eu-central-1.vpce-svc-08e5dfca9572c85c4"
    "eu-west-1"      = "com.amazonaws.vpce.eu-west-1.vpce-svc-09b4eb2bc775f4e8c"
    "eu-west-2"      = "com.amazonaws.vpce.eu-west-2.vpce-svc-05279412bf5353a45"
    "eu-west-3"      = "com.amazonaws.vpce.eu-west-3.vpce-svc-005b039dd0b5f857d"
    "sa-east-1"      = "com.amazonaws.vpce.sa-east-1.vpce-svc-0e61564963be1b43f"
    "us-east-1"      = "com.amazonaws.vpce.us-east-1.vpce-svc-00018a8c3ff62ffdf"
    "us-east-2"      = "com.amazonaws.vpce.us-east-2.vpce-svc-090a8fab0d73e39a6"
    "us-west-1"      = "com.amazonaws.vpce.us-west-1.vpce-svc-04cb91f9372b792fe"
    "us-west-2"      = "com.amazonaws.vpce.us-west-2.vpce-svc-0158114c0c730c3bb"
  }

  # GovCloud endpoint service attachment URIs.
  # Both GovCloud shards operate in us-gov-west-1 but use distinct service IDs.
  # Service Direct is not available in GovCloud.
  # Source: https://docs.databricks.com/aws/en/resources/ip-domain-region
  _workspace_service_names_gov = {
    "civilian" = "com.amazonaws.vpce.us-gov-west-1.vpce-svc-0f25e28401cbc9418"
    "dod"      = "com.amazonaws.vpce.us-gov-west-1.vpce-svc-08fddf710780b2a54"
  }
  _relay_service_names_gov = {
    "civilian" = "com.amazonaws.vpce.us-gov-west-1.vpce-svc-05f27abef1a1a3faa"
    "dod"      = "com.amazonaws.vpce.us-gov-west-1.vpce-svc-05c210a2feea23ad7"
  }

  # Resolved service attachment URIs — custom_service_attachment_uris override the map lookups.
  workspace_service_name = coalesce(
    var.custom_service_attachment_uris.workspace,
    var.databricks_gov_shard != null
    ? local._workspace_service_names_gov[var.databricks_gov_shard]
    : local._workspace_service_names_commercial[var.region]
  )

  relay_service_name = coalesce(
    var.custom_service_attachment_uris.relay,
    var.databricks_gov_shard != null
    ? local._relay_service_names_gov[var.databricks_gov_shard]
    : local._relay_service_names_commercial[var.region]
  )

  # Service direct is only available in commercial regions; disallowed in GovCloud.
  # When custom_service_attachment_uris.service_direct is provided it is used as-is.
  service_direct_service_name = var.custom_service_attachment_uris.service_direct
}
