# Policy allowing EC2 instances to assume a role
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Policy allowing attaching the node's EIP
data "aws_iam_policy_document" "eip_attach" {
  count = local.aws_vars.ec2.eip ? 1 : 0

  statement {
    actions = [
      "ec2:AssociateAddress",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/Name"

      values = [
        "${local.name_prefix}-node",
      ]
    }
  }

  # TODO: narrow the scope
  statement {
    actions = [
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "s3_deploy" {

  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [aws_s3_bucket.deploy.arn]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.deploy.arn}/*"]
  }

}

# Policy allowing attaching the node's EBS volume
data "aws_iam_policy_document" "ebs_attach" {
  statement {
    actions = [
      "ec2:AttachVolume",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/Name"

      values = [
        "${local.name_prefix}-node",
      ]
    }
  }

  statement {
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumeStatus",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "node" {
  name = "${local.name_prefix}-node"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  inline_policy {
    name   = "ebs-attach"
    policy = data.aws_iam_policy_document.ebs_attach.json
  }

  inline_policy {
    name   = "s3-deploy"
    policy = data.aws_iam_policy_document.s3_deploy.json
  }

  # Not all nodes have a matching eip-attach policy, this for_each allows
  # to make it conditional
  dynamic "inline_policy" {
    for_each = {
      for key, val in { "node" = local.node_vars.node } :
      key => val if lookup(val, "eip", false)
    }

    content {
      name   = "eip-attach"
      policy = data.aws_iam_policy_document.eip_attach[0].json
    }
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${local.name_prefix}-node"
    },
  )
}

resource "aws_iam_instance_profile" "node" {
  name = "${local.name_prefix}-node"
  role = aws_iam_role.node.name

  tags = merge(
    local.default_tags,
    {
      Name = "${local.name_prefix}-node"
    },
  )

}
