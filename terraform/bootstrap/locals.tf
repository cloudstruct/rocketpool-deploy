locals {
  pool = terraform.workspace

  default_vars = yamldecode(file("../../vars/defaults.yaml"))
  aws_vars     = yamldecode(file("../../vars/pools/${local.pool}/aws.yaml"))
  rp_vars      = yamldecode(file("../../vars/pools/${local.pool}/rocketpool.yaml"))

  name_prefix = "rocket-pool-${local.pool}"

  default_tags = {
    billing     = "rocketpool"
    env         = "state"
    region      = local.aws_vars.region
    rocket_pool = local.pool
    cloudstruct = "true"
  }

}
