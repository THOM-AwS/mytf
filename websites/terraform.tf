terraform {
  required_providers {
    aws = {
      version = "5.18.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  # profile = local.workspace["aws_profile"]
  region = local.workspace["aws_region"]
}
