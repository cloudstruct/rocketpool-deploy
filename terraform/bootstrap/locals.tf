locals {
  pool = var.pool

  aws_vars = yamldecode(file("../../vars/pools/${local.pool}/aws.yaml"))

  default_tags = {
    billing     = "rocketpool"
    env         = "state"
    region      = local.aws_vars.region
    rocket_pool = local.pool
    cloudstruct = "true"
  }

}
