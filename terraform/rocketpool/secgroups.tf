locals {
  ssh_whitelist = concat(local.default_vars.ssh_whitelist, [try("${data.http.workstation_public_ip[0].body}/32", null)])
}

data "http" "workstation_public_ip" {
  count = try(local.node_vars.global.ssh.allow_workstation_ip, false) ? 1 : 0
  url   = "https://ifconfig.me/ip"
}

resource "aws_security_group" "common" {
  name        = "${local.name_prefix}-common"
  description = "Common security group for nodes in RocketPool pool ${local.pool}"

  vpc_id = module.vpc.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${local.name_prefix}-common"
    },
  )
}

resource "aws_security_group" "core_node" {
  name        = "${local.name_prefix}-core-node"
  description = "Security group for core node in RocketPool pool ${local.pool}"

  vpc_id = module.vpc.vpc_id

  ingress {
    description = "SSH from internet"
    from_port   = local.node_vars.global.ssh.port
    to_port     = local.node_vars.global.ssh.port
    protocol    = "tcp"
    cidr_blocks = local.ssh_whitelist
  }

  ingress {
    description = "Grafana HTTP"
    from_port   = local.rp_vars.grafana.port
    to_port     = local.rp_vars.grafana.port
    protocol    = "tcp"
    cidr_blocks = local.ssh_whitelist
  }

  ingress {
    description      = "ETH1 Discovery"
    from_port        = 30303
    to_port          = 30303
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ETH1 Discovery"
    from_port        = 30303
    to_port          = 30303
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ETH2 Discovery"
    from_port        = 9001
    to_port          = 9001
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ETH2 Discovery"
    from_port        = 9001
    to_port          = 9001
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${local.name_prefix}-node"
    },
  )
}
