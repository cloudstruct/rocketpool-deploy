resource "aws_s3_bucket" "log_bucket" {
  bucket = "cloudstruct-rocketpool-${local.pool}-access-log"
  tags   = local.default_tags
}

resource "aws_s3_bucket_acl" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

}

resource "aws_s3_bucket" "deploy" {
  bucket = local.aws_vars.s3.buckets.deploy.name
  tags   = local.default_tags
}

resource "aws_s3_bucket_acl" "deploy" {
  bucket = aws_s3_bucket.deploy.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deploy" {
  bucket = aws_s3_bucket.deploy.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

}

resource "aws_s3_bucket_logging" "deploy" {
  bucket        = aws_s3_bucket.deploy.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_versioning" "deploy" {
  bucket = aws_s3_bucket.deploy.id
  versioning_configuration {
    status = "Enabled"
  }
}

