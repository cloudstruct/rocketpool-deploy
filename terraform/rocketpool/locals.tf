locals {
  pool = terraform.workspace

  default_vars = yamldecode(file("../../vars/defaults.yaml"))
  aws_vars     = yamldecode(file("../../vars/pools/${local.pool}/aws.yaml"))
  node_vars    = yamldecode(file("../../vars/pools/${local.pool}/node.yaml"))
  rp_vars      = yamldecode(file("../../vars/pools/${local.pool}/rocketpool.yaml"))

  name_prefix = "rocket-pool-${local.pool}"

  default_tags = {
    billing     = "rocketpool"
    rocket_pool = local.pool
  }

}
