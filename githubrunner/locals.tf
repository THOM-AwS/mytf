locals {

  env = {
    prod = {
      aws_profile = "hamer"
      aws_region = "ap-southeast-2"
      vpc_id     = "vpc-018d82058447968b7" 
      subnet_ids = ["subnet-094eb31fc174ed123", "subnet-060b94669a3c2d1a8", "subnet-05016f77be825ba9b"]

      environment = "Prod"

      github_app = {
        key_base64     = "base64string"
        id             = "139153"
        client_id      = "Iv1.23641bb57b3756bb"
        client_secret  = "client_secret"
        webhook_secret = "webhook_secret"
      }
    }
  }
  workspace = local.env[terraform.workspace]
}
