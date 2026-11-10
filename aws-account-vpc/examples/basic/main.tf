terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = ".."

  resource_prefix      = "my-workspace"
  vpc_cidr             = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.32.0/20", "10.0.48.0/20"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  azs                  = ["us-east-1a", "us-east-1b"]
}
