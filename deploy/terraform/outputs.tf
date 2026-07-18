output "state_bucket_name" {
  description = "Name of the S3 bucket that stores Terraform remote state for all mootmaker projects."
  value       = aws_s3_bucket.remote_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket that stores Terraform remote state."
  value       = aws_s3_bucket.remote_state.arn
}

output "aws_region" {
  description = "AWS region the state bucket lives in."
  value       = var.aws_region
}
