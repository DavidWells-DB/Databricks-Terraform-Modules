terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    aws = {
      # aws_vpc_peering_connection, aws_vpc_peering_connection_accepter, aws_route stable since 5.0
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
