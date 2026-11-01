terraform {
  required_providers {
    aws = {
      version = "5.18.0"
      source  = "hashicorp/aws"
    }
    # Only so the removed null_resources can be destroyed. Drop once they are
    # out of state.
    null = {
      source = "hashicorp/null"
    }
  }
}

provider "aws" {
  profile = "hamer"
  region  = local.workspace["aws_region"]
}
