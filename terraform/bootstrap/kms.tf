resource "aws_kms_key" "terraform_state" {
  description             = "KMS key used to encrypt the S3 bucket storing Terraform state of Rocketpool infrastructure."
  deletion_window_in_days = 14
  tags = merge(
    local.tags
  )
}

resource "aws_kms_alias" "terraform_key" {
  name          = "alias/cloudstruct_rocketpool_terraform_key"
  target_key_id = aws_kms_key.terraform_state.key_id
}
