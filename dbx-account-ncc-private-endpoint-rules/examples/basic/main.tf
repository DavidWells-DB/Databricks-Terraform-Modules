terraform {
  required_version = ">= 1.7"
}

module "ncc_private_endpoint_rules" {
  source = "../../"

  network_connectivity_config_id = var.network_connectivity_config_id
  cloud                          = "aws"
  private_endpoint_rules         = var.private_endpoint_rules
}
