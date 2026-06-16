terraform {
  required_version = ">= 1.7.0" # mock_provider in terraform test

  required_providers {
    aws = {
      # 5.0+: stable aws_vpc_endpoint with endpoint_policy and consistent tagging
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
