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
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.0"
    }
  }

  required_version = ">= 0.13, < 2"

}

provider "aws" {
  region = local.aws_vars.region
}
