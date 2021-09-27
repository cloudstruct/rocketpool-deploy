# Policy allowing EC2 instances to assume a role
data "aws_iam_policy_document" "assume_role" {
  for_each = local.nodes

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
  for_each = {
    for key, val in local.nodes :
    key => val if lookup(val, "eip", false)
  }

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
        "${local.name_prefix}-node-${each.key}",
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

# Policy allowing attaching the node's EBS volume
data "aws_iam_policy_document" "ebs_attach" {
  for_each = local.nodes

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
        "${local.name_prefix}-node-${each.key}",
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
  for_each = local.nodes

  name = "${local.name_prefix}-node-${each.key}"

  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json

  inline_policy {
    name   = "ebs-attach"
    policy = data.aws_iam_policy_document.ebs_attach[each.key].json
  }

  # Not all nodes have a matching eip-attach policy, so this is a bit hand-wavy
  # to make it conditional
  dynamic "inline_policy" {
    for_each = {
      for key, val in { (each.key) = each.value } :
      key => val if lookup(val, "eip", false)
    }

    content {
      name   = "eip-attach"
      policy = data.aws_iam_policy_document.eip_attach[inline_policy.key].json
    }
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${local.name_prefix}-node-${each.key}"
    },
  )
}

resource "aws_iam_instance_profile" "node" {
  for_each = local.nodes

  name = "${local.name_prefix}-node-${each.key}"
  role = aws_iam_role.node[each.key].name
}
