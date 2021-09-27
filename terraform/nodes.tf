locals {
  bootstrap_template_vars = {
    aws_vars  = local.aws_vars
    node_vars = local.node_vars
    eip_id = {
      for key, val in local.nodes :
      key => aws_eip.node[key].id if lookup(val, "eip", false)
    }
    ebs_volume_id = {
      for key, val in local.nodes :
      key => aws_ebs_volume.node_data[key].id
    }
  }
}

# Lookup Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
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
  algorithm = "RSA"
}

resource "aws_key_pair" "common" {
  key_name   = local.name_prefix
  public_key = tls_private_key.ssh_keypair.public_key_openssh
}

# Cloud-init config template
data "template_cloudinit_config" "node" {
  for_each = local.nodes

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
          ${indent(6, templatefile("${path.root}/templates/bootstrap.sh.tpl", merge(local.bootstrap_template_vars, { node_key = each.key, node_value = each.value })))}
    EOF
  }
}

# Launch templates
resource "aws_launch_template" "node" {
  for_each = local.nodes

  name_prefix   = "${local.name_prefix}-node-${each.key}"
  image_id      = data.aws_ami.ubuntu.image_id
  instance_type = local.aws_vars.ec2[each.value.type].instance_type
  key_name      = try(each.value.keypair, aws_key_pair.common.key_name)

  update_default_version = true

  user_data = data.template_cloudinit_config.node[each.key].rendered

  disable_api_termination = true

  vpc_security_group_ids = concat(
    [aws_security_group.common.id],
    lookup(each.value, "extra_secgroups", []),
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.node[each.key].name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${local.name_prefix}-node-${each.key}"
    },
  )
}

# Data EBS volumes
resource "aws_ebs_volume" "node_data" {
  for_each = local.nodes

  availability_zone = local.aws_vars.vpc.az

  size = try(each.value.ebs_volume_size, 1000)
  type = "gp3"

  tags = merge(
    local.default_tags,
    {
      Name = "${local.name_prefix}-node-${each.key}"
    },
  )
}

# Autoscaling groups
resource "aws_autoscaling_group" "node" {
  for_each = local.nodes

  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  vpc_zone_identifier = [each.value.subnet]

  launch_template {
    id      = aws_launch_template.node[each.key].id
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
        Name          = "${local.name_prefix}-node-${each.key}"
        eth_node_type = each.value.type
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
  for_each = {
    for key, val in local.nodes :
    key => val if lookup(val, "eip", false)
  }

  vpc = true

  tags = merge(
    local.default_tags,
    {
      Name = "${local.name_prefix}-node-${each.key}"
    },
  )
}
