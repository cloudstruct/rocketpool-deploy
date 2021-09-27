locals {
  pool = terraform.workspace

  defaults_vars = yamldecode(file("vars/defaults.yaml"))
  aws_vars      = yamldecode(file("vars/pools/${local.pool}/aws.yaml"))
  node_vars     = yamldecode(file("vars/pools/${local.pool}/node.yaml"))
  rp_vars       = yamldecode(file("vars/pools/${local.pool}/rocketpool.yaml"))

  name_prefix = "rocket-pool-${local.pool}"

  default_tags = {
    billing     = "rocketpool"
    rocket_pool = local.pool
    nodes       = join(",", keys(local.aws_vars.ec2))
  }

  nodes = { for node, values in local.node_vars.nodes : node => merge(
    values,
    {
      extra_secgroups = [aws_security_group.core_node.id]
      subnet          = module.vpc.public_subnets[0]
    }
  ) }

}
