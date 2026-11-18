terraform {
  required_version = ">= 1.7"

  required_providers {
    databricks = {
      source                = "databricks/databricks"
      version               = ">= 1.81"
      configuration_aliases = [databricks.account]
    }
  }
}
