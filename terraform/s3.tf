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
