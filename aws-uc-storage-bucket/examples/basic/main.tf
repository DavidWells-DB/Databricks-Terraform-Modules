terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "uc_storage_bucket" {
  source = "../.."

  bucket_name   = var.bucket_name
  kms_key_arn   = var.kms_key_arn
  force_destroy = var.force_destroy

  tags = {
    Module  = "aws-uc-storage-bucket"
    Example = "basic"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for the provider."
  default     = "us-east-1"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique name of the dedicated S3 bucket for a Unity Catalog catalog's managed storage."
}

variable "kms_key_arn" {
  type        = string
  description = "Optional KMS key ARN for bucket encryption. Null = SSE-S3 (AES256)."
  default     = null
}

variable "force_destroy" {
  type        = bool
  description = "Allow the bucket and all contained objects to be destroyed by Terraform."
  default     = false
}

output "storage_root" {
  description = "Unity Catalog storage-root URL for the bucket (s3://<bucket>)."
  value       = module.uc_storage_bucket.storage_root
}

output "bucket_arn" {
  description = "ARN of the dedicated UC bucket."
  value       = module.uc_storage_bucket.bucket_arn
}
