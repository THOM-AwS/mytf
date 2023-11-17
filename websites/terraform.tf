terraform {
  required_providers {
    aws = {
      version = "5.18.1"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = local.workspace["aws_region"]
}
