locals {
  # Databricks PSC workspace (plproxy) service attachment URIs per GCP region.
  # Source: https://docs.databricks.com/gcp/en/resources/ip-domain-region#psc
  workspace_psc_attachment_map = {
    "asia-northeast1"         = "projects/general-prod-asianortheast1-01/regions/asia-northeast1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "asia-south1"             = "projects/gen-prod-asias1-01/regions/asia-south1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "asia-southeast1"         = "projects/general-prod-asiasoutheast1-01/regions/asia-southeast1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "australia-southeast1"    = "projects/general-prod-ausoutheast1-01/regions/australia-southeast1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "europe-west1"            = "projects/general-prod-europewest1-01/regions/europe-west1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "europe-west2"            = "projects/general-prod-europewest2-01/regions/europe-west2/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "europe-west3"            = "projects/general-prod-europewest3-01/regions/europe-west3/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "me-central2"             = "projects/gen-prod-mec2-01/regions/me-central2/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "northamerica-northeast1" = "projects/general-prod-nanortheast1-01/regions/northamerica-northeast1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "southamerica-east1"      = "projects/gen-prod-saeast1-01/regions/southamerica-east1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "us-central1"             = "projects/gcp-prod-general/regions/us-central1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "us-east1"                = "projects/general-prod-useast1-01/regions/us-east1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "us-east4"                = "projects/general-prod-useast4-01/regions/us-east4/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "us-west1"                = "projects/general-prod-uswest1-01/regions/us-west1/serviceAttachments/plproxy-psc-endpoint-all-ports"
    "us-west4"                = "projects/general-prod-uswest4-01/regions/us-west4/serviceAttachments/plproxy-psc-endpoint-all-ports"
  }

  # Databricks PSC SCC relay (ngrok) service attachment URIs per GCP region.
  # Source: https://docs.databricks.com/gcp/en/resources/ip-domain-region#psc
  relay_psc_attachment_map = {
    "asia-northeast1"         = "projects/prod-gcp-asia-northeast1/regions/asia-northeast1/serviceAttachments/ngrok-psc-endpoint"
    "asia-south1"             = "projects/prod-gcp-asia-south1/regions/asia-south1/serviceAttachments/ngrok-psc-endpoint"
    "asia-southeast1"         = "projects/prod-gcp-asia-southeast1/regions/asia-southeast1/serviceAttachments/ngrok-psc-endpoint"
    "australia-southeast1"    = "projects/prod-gcp-australia-southeast1/regions/australia-southeast1/serviceAttachments/ngrok-psc-endpoint"
    "europe-west1"            = "projects/prod-gcp-europe-west1/regions/europe-west1/serviceAttachments/ngrok-psc-endpoint"
    "europe-west2"            = "projects/prod-gcp-europe-west2/regions/europe-west2/serviceAttachments/ngrok-psc-endpoint"
    "europe-west3"            = "projects/prod-gcp-europe-west3/regions/europe-west3/serviceAttachments/ngrok-psc-endpoint"
    "me-central2"             = "projects/prod-gcp-me-central2/regions/me-central2/serviceAttachments/ngrok-psc-endpoint"
    "northamerica-northeast1" = "projects/prod-gcp-na-northeast1/regions/northamerica-northeast1/serviceAttachments/ngrok-psc-endpoint"
    "southamerica-east1"      = "projects/prod-gcp-southamerica-east1/regions/southamerica-east1/serviceAttachments/ngrok-psc-endpoint"
    "us-central1"             = "projects/prod-gcp-us-central1/regions/us-central1/serviceAttachments/ngrok-psc-endpoint"
    "us-east1"                = "projects/prod-gcp-us-east1/regions/us-east1/serviceAttachments/ngrok-psc-endpoint"
    "us-east4"                = "projects/prod-gcp-us-east4/regions/us-east4/serviceAttachments/ngrok-psc-endpoint"
    "us-west1"                = "projects/prod-gcp-us-west1/regions/us-west1/serviceAttachments/ngrok-psc-endpoint"
    "us-west4"                = "projects/prod-gcp-us-west4/regions/us-west4/serviceAttachments/ngrok-psc-endpoint"
  }

  # Effective service attachment URIs — use caller override when provided.
  workspace_psc_attachment = (
    var.workspace_psc_service_attachment != null
    ? var.workspace_psc_service_attachment
    : local.workspace_psc_attachment_map[var.region]
  )

  relay_psc_attachment = (
    var.relay_psc_service_attachment != null
    ? var.relay_psc_service_attachment
    : local.relay_psc_attachment_map[var.region]
  )

  # Private Access Settings name — default to <prefix>-pas when not supplied.
  pas_name = (
    var.private_access_settings_name != null
    ? var.private_access_settings_name
    : "${var.resource_prefix}-pas"
  )
}
