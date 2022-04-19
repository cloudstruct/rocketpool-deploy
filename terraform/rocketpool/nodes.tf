locals {
  bootstrap_template_vars = {
    aws_vars  = local.aws_vars
    node_vars = local.node_vars
    eip_id = try(aws_eip.node[0].id, "false")
    ebs_volume_id = aws_ebs_volume.node_data.id
    rocketpool_pool    = local.pool
    rocketpool_version = local.rp_vars.rocketpool.version
    s3_deploy_bucket   = aws_s3_bucket.deploy.id
  }
}

# Lookup Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-${try(local.aws_vars.ec2.instance_arch, "amd64")}-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Canonical
  owners = ["099720109477"]
}

# Generate SSH keypair
resource "tls_private_key" "ssh_keypair" {
  count     = local.aws_vars.create_rsa_key ? 1 : 0
  algorithm = "RSA"
}

resource "aws_key_pair" "common" {
  count = try(local.aws_vars.upload_rsa_key, local.aws_vars.create_rsa_key, false) ? 1 : 0

  key_name   = local.name_prefix
  public_key = local.aws_vars.create_rsa_key ? tls_private_key.ssh_keypair[0].public_key_openssh : local.default_vars.ssh_public_key

  tags = local.default_tags

}

# Cloud-init config template
data "template_cloudinit_config" "node" {
  gzip = false

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = <<-EOF
    #cloud-config

    packages:
      - awscli
      - jq
      - python3-pip

    runcmd:
      - /usr/local/bin/bootstrap.sh

    write_files:
      - path: '/usr/local/bin/bootstrap.sh'
        permissions: '0755'
        owner: 'root:root'
        content: |
          ${indent(6, templatefile("${path.root}/templates/bootstrap.sh.tpl", local.bootstrap_template_vars))}
    EOF
  }
}

# Launch templates
resource "aws_launch_template" "node" {
  name_prefix   = "${local.name_prefix}-node"
  image_id      = data.aws_ami.ubuntu.image_id
  instance_type = local.aws_vars.ec2.instance_type
  key_name      = try(aws_key_pair.common[0].key_name, local.node_vars.node.keypair)

  update_default_version = true

  user_data = data.template_cloudinit_config.node.rendered

  disable_api_termination = true

  vpc_security_group_ids = concat(
    [aws_security_group.common.id],
    lookup(local.node_vars.node, "extra_secgroups", []),
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.node.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${local.name_prefix}-node"
    },
  )
}

# Data EBS volumes
resource "aws_ebs_volume" "node_data" {
  availability_zone = local.aws_vars.vpc.az

  encrypted = true

  size = try(local.node_vars.node.ebs_volume_size, 1000)
  type = "gp3"

  tags = merge(
    local.default_tags,
    {
      Name = "${local.name_prefix}-node"
    },
  )
}

# Autoscaling groups
# tflint-ignore: aws_resource_missing_tags
resource "aws_autoscaling_group" "node" {
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  vpc_zone_identifier = [module.vpc.public_subnets[0]]

  launch_template {
    id      = aws_launch_template.node.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupInServiceInstances",
    "GroupTerminatingInstances",
  ]

  dynamic "tag" {
    for_each = merge(
      local.default_tags,
      {
        Name          = "${local.name_prefix}-node"
        eth_node_type = "core"
        eth_network   = try(local.node_vars.eth_network, "mainnet")
      },
    )

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# EIP
resource "aws_eip" "node" {
  count = local.node_vars.node.eip ? 1 : 0

  vpc = true

  tags = merge(
    local.default_tags,
    {
      Name = "${local.name_prefix}-node"
    },
  )

}
