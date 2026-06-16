terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    aws = {
      # 5.0+: stable aws_ec2_transit_gateway, aws_ec2_transit_gateway_vpc_attachment,
      # aws_ec2_transit_gateway_route_table, associations, and propagations used in this module
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
