resource "aws_s3_bucket_policy" "this" {
  bucket = var.bucket_name
  policy = local.policy
}
