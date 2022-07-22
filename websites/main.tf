module "aws-static-website" {
  source      = "github.com/THOM-AwS/aws-static-website"
  domain_name = local.workspace["domain_name"]
  hosted_zone = local.workspace["domain_name"]
  environment = "prod"
  tags = {
    "Stack" = local.workspace["domain_name"]
  }
}