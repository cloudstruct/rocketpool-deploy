resource "aws_s3_bucket" "log_bucket" {
  count  = try(local.aws_vars.s3.buckets.tfstate.create, true) ? 1 : 0
  bucket = "cloudstruct-rocketpool-${local.aws_vars.region}-access-log-${terraform.workspace}"

  force_destroy = true

  tags = local.default_tags

}

resource "aws_s3_bucket_acl" "log_bucket" {
  count  = try(local.aws_vars.s3.buckets.tfstate.create, true) ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket" {
  count  = try(local.aws_vars.s3.buckets.tfstate.create, true) ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket" "terraform_state" {
  count  = try(local.aws_vars.s3.buckets.tfstate.create, true) ? 1 : 0
  bucket = "cloudstruct-rocketpool-tf-state-${terraform.workspace}"

  force_destroy = true

  tags = local.default_tags
}

resource "aws_s3_bucket_logging" "terraform_state" {
  count  = try(local.aws_vars.s3.buckets.tfstate.create, true) ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  target_bucket = aws_s3_bucket.log_bucket[0].id
  target_prefix = "log/"
}

resource "aws_s3_bucket_acl" "terraform_state" {
  count  = try(local.aws_vars.s3.buckets.tfstate.create, true) ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  count  = try(local.aws_vars.s3.buckets.tfstate.create, true) ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count  = try(local.aws_vars.s3.buckets.tfstate.create, true) ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
