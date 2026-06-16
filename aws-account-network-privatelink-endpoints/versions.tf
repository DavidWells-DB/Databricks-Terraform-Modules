terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    aws = {
      # 5.0+: stable aws_vpc_endpoint with private_dns_enabled and consistent tagging
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    databricks = {
      # 1.50+: stable databricks_mws_vpc_endpoint and databricks_mws_private_access_settings
      # with GovCloud account host support
      source                = "databricks/databricks"
      version               = ">= 1.50"
      configuration_aliases = [databricks.account]
    }
  }
}
