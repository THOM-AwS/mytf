terraform {
  required_providers {
    aws = {
      version = "3.50.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = local.workspace["aws_profile"]
  region  = local.workspace["aws_region"]
}