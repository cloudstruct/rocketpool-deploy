module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name = local.name_prefix
  cidr = local.aws_vars.vpc.cidr

  azs             = [local.aws_vars.vpc.az]
  private_subnets = [local.aws_vars.vpc.private_subnet]
  public_subnets  = [local.aws_vars.vpc.public_subnet]

  enable_nat_gateway = false

  tags = local.default_tags
}
