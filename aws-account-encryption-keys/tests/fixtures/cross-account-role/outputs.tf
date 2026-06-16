output "cross_account_role_arn" {
  description = "ARN of the test cross-account IAM role"
  value       = aws_iam_role.test_cross_account.arn
}

output "aws_account_id" {
  description = "AWS account ID where the role was created"
  value       = data.aws_caller_identity.current.account_id
}
