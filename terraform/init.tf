terraform {
  backend "s3" {
    bucket = "cloudstruct-rocket-pool-tf-state"
    key    = "tf-state"
    region = "us-east-1"
  }
}

provider "aws" {
  region = local.aws_vars.region
}
