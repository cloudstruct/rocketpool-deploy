terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "< 4"
    }
  }

  required_version = ">= 1, < 1.1"

}

provider "aws" {
  region = local.aws_vars.region
}
