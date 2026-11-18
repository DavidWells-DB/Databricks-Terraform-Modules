mock_provider "databricks" { alias = "account" }

variables {
  network_connectivity_config_id = "01234567-89ab-cdef-0123-456789abcdef"
  cloud                          = "aws"
}

run "aws_s3_rule" {
  command = plan

  variables {
    private_endpoint_rules = [{
      key              = "artifacts"
      endpoint_service = "com.amazonaws.us-east-1.s3"
      resource_names   = ["customer-artifacts"]
    }]
  }

  assert {
    condition     = databricks_mws_ncc_private_endpoint_rule.this["artifacts"].resource_names[0] == "customer-artifacts"
    error_message = "The AWS endpoint service and bucket must reach the NCC rule"
  }
}

run "azure_resource_rule" {
  command = plan

  variables {
    cloud = "azure"
    private_endpoint_rules = [{
      key         = "storage"
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/artifacts"
      group_id    = "blob"
    }]
  }

  assert {
    condition     = databricks_mws_ncc_private_endpoint_rule.this["storage"].group_id == "blob"
    error_message = "The Azure resource ID and group ID must reach the NCC rule"
  }
}

run "invalid_aws_rule_rejected" {
  command = plan

  variables {
    private_endpoint_rules = [{ key = "invalid", resource_names = ["bucket"] }]
  }

  expect_failures = [var.private_endpoint_rules]
}
