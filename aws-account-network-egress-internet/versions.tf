terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    aws = {
      # aws_nat_gateway domain attribute stable since 5.0
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
