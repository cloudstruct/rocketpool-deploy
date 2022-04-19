terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    tls = {
      source  = "hashicorp/tls"
    }
  }

  required_version = ">= 0.13, < 2"

}

provider "aws" {
  region = local.aws_vars.region
}
