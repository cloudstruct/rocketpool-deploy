locals {
  bundle_files = [
    "${path.module}/../../ansible",
    "${path.module}/../../vars",
    "${path.module}/../../requirements.txt"
  ]
}

# Template local-update.sh file
data "template_file" "local_update" {
  template = file("${path.module}/templates/local-update.sh.tpl")
  vars = {
    rocketpool_pool = local.pool
    region = local.aws_vars.region
  }
}

resource "local_file" "local_update" {
  content = data.template_file.local_update.rendered
  filename = "${path.module}/../../ansible/local-update.sh"
}

# Generate script which will create tarball for upload
data "template_file" "tar_sh" {
  template = <<EOF
#!/bin/bash
tar $* %1>/dev/null %2>/dev/null
echo '{"result":"success"}'
EOF
}

resource "local_file" "tar_sh" {
  filename = "${path.module}/../scripts/tar.sh"
  content  = data.template_file.tar_sh.rendered
}

data "external" "tar_sh" {
  program    = [local_file.tar_sh.filename, "-cvzf", "${path.module}/ansible-${local.rp_vars.rocketpool.version}.tar.gz", "${join(" ", local.bundle_files)}"]
  depends_on = [data.template_file.tar_sh, local_file.local_update]
}

resource "aws_s3_object" "ansible_tar_gz" {
  depends_on = [data.external.tar_sh, local_file.local_update]
  bucket     = aws_s3_bucket.deploy.id
  key        = "ansible-${local.rp_vars.rocketpool.version}.tar.gz"
  source     = "${path.module}/ansible-${local.rp_vars.rocketpool.version}.tar.gz"
  etag       = try(filemd5("${path.module}/ansible-${local.rp_vars.rocketpool.version}.tar.gz"), null)
  tags       = local.default_tags
}
