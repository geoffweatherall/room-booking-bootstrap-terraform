data "aws_caller_identity" "current" {}

# Shared Terraform remote state storage for all room-booking-* projects.
# prevent_destroy guards against an accidental `terraform destroy` wiping out
# every project's state in one go.
resource "aws_s3_bucket" "remote_state" {
  bucket = "remote-state-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
