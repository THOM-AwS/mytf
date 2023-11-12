locals {

  env = {
    hamer = {
      aws_profile = "hamer"
      aws_region  = "us-east-1"
      domain_name = "hamer.cloud"
    }
    wcplumbing = {
      aws_profile = "hamer"
      aws_region  = "us-east-1"
      domain_name = "wcplumbing.com.au"
    }
  }

  workspace = local.env[terraform.workspace]
}