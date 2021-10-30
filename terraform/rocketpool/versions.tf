terraform {
  backend "s3" {
    bucket         = "cloudstruct-rocketpool-tf-state"
    key            = "rocketpool.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    kms_key_id     = "alias/cloudstruct_rocketpool_tfkey"
  }

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
