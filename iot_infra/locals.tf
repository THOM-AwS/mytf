locals {
  env = {
    iot = {
      aws_profile     = "hamer"
      aws_region      = "ap-southeast-2"
      resource_prefix = "hamer"
      policy_name     = "iot_policy"
      thing_name      = "esp320001"
      iam_role_name   = "iot_role"
      tags_all    = {
          "repository" = "hamer/iot"
          "workspace"  = "iot"
        }
    }
  }

  workspace = local.env[terraform.workspace]
}
