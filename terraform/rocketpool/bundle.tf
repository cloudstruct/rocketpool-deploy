locals {
  bundle_files = [
    "${path.root}/../ansible",
    "${path.root}/../vars",
    "${path.root}/../requirements.txt"
  ]
}

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
  program    = [local_file.tar_sh.filename, "-cvzf", "${path.root}/ansible-${local.rp_vars.rocketpool.version}.tar.gz", "${join(" ", local.bundle_files)}"]
  depends_on = [data.template_file.tar_sh]
}

resource "aws_s3_bucket_object" "ansible_tar_gz" {
  depends_on = [data.external.tar_sh]
  bucket     = aws_s3_bucket.deploy.id
  key        = "ansible-${local.rp_vars.rocketpool.version}.tar.gz"
  source     = "${path.root}/ansible-${local.rp_vars.rocketpool.version}.tar.gz"
  etag       = try(filemd5("${path.root}/ansible-${local.rp_vars.rocketpool.version}.tar.gz"), null)
  tags       = local.default_tags

}
