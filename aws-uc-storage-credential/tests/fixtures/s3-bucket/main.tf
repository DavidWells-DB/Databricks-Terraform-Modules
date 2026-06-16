variable "bucket_name" {
  type = string
}

resource "aws_s3_bucket" "test" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name        = "tftest-uc-storage-credential"
    Environment = "test"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.test.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.test.arn
}
