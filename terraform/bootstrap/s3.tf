resource "aws_s3_bucket" "log_bucket" {
  bucket = "cloudstruct-rocketpool-access-log"
  acl    = "log-delivery-write"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.default_tags

}

resource "aws_s3_bucket" "terraform-state" {
  bucket = "cloudstruct-rocketpool-terraform-state"
  acl    = "private"

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.terraform-state.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = local.default_tags
}
