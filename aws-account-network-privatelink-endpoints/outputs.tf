output "workspace_vpc_endpoint_id" {
  description = "Databricks vpc_endpoint_id for the workspace (REST API) endpoint. Pass to aws-account-network-vpc's vpc_endpoint_ids.rest_api input or to allowed_vpc_endpoint_ids when private_access_level = \"ENDPOINT\"."
  value       = databricks_mws_vpc_endpoint.workspace.vpc_endpoint_id
}

output "relay_vpc_endpoint_id" {
  description = "Databricks vpc_endpoint_id for the SCC relay endpoint. Pass to aws-account-network-vpc's vpc_endpoint_ids.dataplane_relay input."
  value       = databricks_mws_vpc_endpoint.relay.vpc_endpoint_id
}

output "service_direct_vpc_endpoint_id" {
  description = "Databricks vpc_endpoint_id for the service-direct endpoint. null when enable_service_direct = false."
  value       = var.enable_service_direct ? databricks_mws_vpc_endpoint.service_direct[0].vpc_endpoint_id : null
}

output "private_access_settings_id" {
  description = "Databricks private_access_settings_id. Pass to aws-account-workspace's private_access_settings_id input when creating a workspace with PrivateLink."
  value       = databricks_mws_private_access_settings.this.private_access_settings_id
}

output "security_group_id" {
  description = "ID of the AWS security group created for the PrivateLink interface endpoints."
  value       = aws_security_group.this.id
}

output "workspace_aws_vpc_endpoint_id" {
  description = "AWS-side ID of the workspace (REST API) interface endpoint (e.g. vpce-xxxxxxxx). Useful for cross-referencing in AWS Console or CloudFormation."
  value       = aws_vpc_endpoint.workspace.id
}

output "relay_aws_vpc_endpoint_id" {
  description = "AWS-side ID of the SCC relay interface endpoint (e.g. vpce-xxxxxxxx)."
  value       = aws_vpc_endpoint.relay.id
}

output "service_direct_aws_vpc_endpoint_id" {
  description = "AWS-side ID of the service-direct interface endpoint. null when enable_service_direct = false."
  value       = var.enable_service_direct ? aws_vpc_endpoint.service_direct[0].id : null
}

output "workspace_service_name" {
  description = "Resolved AWS endpoint service attachment URI for the workspace endpoint. Useful for verification and debugging — confirms the correct Databricks regional service was targeted."
  value       = local.workspace_service_name
}

output "relay_service_name" {
  description = "Resolved AWS endpoint service attachment URI for the SCC relay endpoint."
  value       = local.relay_service_name
}
