terraform {
  backend "s3" {
    region         = "us-east-2"
    bucket         = "cloudstruct-rocketpool-tf-state"
    key            = "rocketpool.tfstate"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    kms_key_id     = "alias/cloudstruct_rocketpool_tfkey"
  }

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
