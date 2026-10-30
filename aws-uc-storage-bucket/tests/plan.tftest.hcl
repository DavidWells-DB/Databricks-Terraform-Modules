mock_provider "aws" {
  mock_resource "aws_s3_bucket" {
    defaults = {
      id  = "my-catalog-uc"
      arn = "arn:aws:s3:::my-catalog-uc"
    }
  }

  mock_resource "aws_s3_bucket_server_side_encryption_configuration" {
    defaults = {
      id = "my-catalog-uc"
    }
  }

  mock_resource "aws_s3_bucket_public_access_block" {
    defaults = {
      id = "my-catalog-uc"
    }
  }
}

variables {
  bucket_name = "my-catalog-uc"
}

run "bucket_created_with_input_name" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket == "my-catalog-uc" && aws_s3_bucket.this.force_destroy == false
    error_message = "Bucket should use the bucket_name input; force_destroy defaults to false"
  }
}

run "storage_root_output_format" {
  command = plan

  assert {
    condition     = output.storage_root == "s3://my-catalog-uc"
    error_message = "storage_root should be s3://<bucket-name>"
  }
}

run "default_encryption_is_sse_s3" {
  command = plan

  assert {
    condition     = flatten(aws_s3_bucket_server_side_encryption_configuration.this.rule[*].apply_server_side_encryption_by_default[*].sse_algorithm) == ["AES256"]
    error_message = "Without a KMS key the bucket must default to SSE-S3 (AES256)"
  }
}

run "kms_encryption_when_key_supplied" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/abcd1234-5678-90ef-ghij-klmnopqrstuv"
  }

  assert {
    condition     = flatten(aws_s3_bucket_server_side_encryption_configuration.this.rule[*].apply_server_side_encryption_by_default[*].sse_algorithm) == ["aws:kms"] && one([for r in aws_s3_bucket_server_side_encryption_configuration.this.rule : r.bucket_key_enabled]) == true
    error_message = "With a KMS key the bucket must use aws:kms with bucket_key_enabled"
  }
}

run "public_access_fully_blocked" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls && aws_s3_bucket_public_access_block.this.block_public_policy && aws_s3_bucket_public_access_block.this.ignore_public_acls && aws_s3_bucket_public_access_block.this.restrict_public_buckets
    error_message = "All four public-access blocks must be on — UC managed storage is accessed via the credential's IAM role, never publicly"
  }
}

run "invalid_bucket_name_rejected" {
  command = plan

  variables {
    bucket_name = "Bad_Name!"
  }

  expect_failures = [var.bucket_name]
}

run "too_short_bucket_name_rejected" {
  command = plan

  variables {
    bucket_name = "ab"
  }

  expect_failures = [var.bucket_name]
}
