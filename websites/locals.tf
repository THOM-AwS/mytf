locals {

  env = {
    hamer = {
      aws_profile = "hamer"
      aws_region  = "us-east-1"
      domain_name = "hamer.cloud"
    }
  }

  workspace = local.env[terraform.workspace]
}
