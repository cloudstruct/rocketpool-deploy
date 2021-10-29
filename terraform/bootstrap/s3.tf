resource "aws_s3_bucket" "log_bucket" {
  count  = try(local.aws_vars.s3.buckets.tfstate.create, true) ? 1 : 0
  bucket = "cloudstruct-rocketpool-${local.aws_vars.region}-access-log"
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
  count  = try(local.aws_vars.s3.buckets.tfstate.create, true) ? 1 : 0
  bucket = "cloudstruct-rocketpool-tf-state"
  acl    = "private"

  logging {
    target_bucket = aws_s3_bucket.log_bucket.0.id
    target_prefix = "log/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.terraform_state.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = local.default_tags
}
