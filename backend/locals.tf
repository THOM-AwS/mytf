locals {
  env = {
    global = {
      aws_profile     = "hamer"
      aws_region      = "ap-southeast-2"
      resource_prefix = "hamer"
    }
  }

  workspace = local.env[terraform.workspace]
}
