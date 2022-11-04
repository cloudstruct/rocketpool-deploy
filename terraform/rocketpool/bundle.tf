locals {
  bundle_files = [
    "${path.module}/../../ansible",
    "${path.module}/../../vars",
    "${path.module}/../../requirements.txt"
  ]
  bundle_vars = {
    rocketpool_pool = local.pool
    region          = local.aws_vars.region
  }
}

resource "local_file" "local_update" {
  content  = templatefile("${path.module}/templates/local-update.sh.tpl", local.bundle_vars)
  filename = "${path.module}/../../ansible/local-update.sh"
}

resource "local_file" "tar_sh" {
  filename       = "${path.module}/../scripts/tar.sh"
  content_base64 = "IyEvYmluL2Jhc2gKdGFyICQqICUxPi9kZXYvbnVsbCAlMj4vZGV2L251bGwKZWNobyAneyJyZXN1bHQiOiJzdWNjZXNzIn0nCg=="
}

data "external" "tar_sh" {
  program    = [local_file.tar_sh.filename, "-cvzf", "${path.module}/ansible-${local.rp_vars.rocketpool.version}.tar.gz", join(" ", local.bundle_files)]
  depends_on = [local_file.local_update]
}

resource "aws_s3_object" "ansible_tar_gz" {
  depends_on = [data.external.tar_sh, local_file.local_update]
  bucket     = aws_s3_bucket.deploy.id
  key        = "ansible-${local.rp_vars.rocketpool.version}.tar.gz"
  source     = "${path.module}/ansible-${local.rp_vars.rocketpool.version}.tar.gz"
  etag       = try(filemd5("${path.module}/ansible-${local.rp_vars.rocketpool.version}.tar.gz"), null)
  tags       = local.default_tags
}
