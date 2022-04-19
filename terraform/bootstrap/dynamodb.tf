resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform-state-lock-${terraform.workspace}"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    { "Name" = "terraform-state-lock-${terraform.workspace}" },
    local.default_tags
  )

}
