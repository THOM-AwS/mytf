module "aws-static-website" {
  source                  = "github.com/THOM-AwS/aws-static-website?ref=v1.1.0"
  domain_name             = local.workspace["domain_name"]
  hosted_zone             = local.workspace["domain_name"]
  environment             = "prod"
  security_headers_source = "${path.module}/secheader.py"
  tags = {
    "Stack" = local.workspace["domain_name"]
  }
}
data "aws_caller_identity" "current" {}
