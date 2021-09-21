
module "github-runner_runners" {
  source  = "philips-labs/github-runner/aws//modules/runners"
  version = "0.18.1"

  aws_region = local.workspace["aws_region"]
  vpc_id     = local.workspace["vpc_id"]
  subnet_ids = local.workspace["subnet_ids"]

  environment = local.workspace["environment"]

  github_app = {
    key_base64     = local.workspace["key_base64"]
    id             = local.workspace["id"]
    client_id      = local.workspace["client_id"]
    client_secret  = local.workspace["client_secret"]
    webhook_secret = local.workspace["webhook_secret"]
  }

  webhook_lambda_zip                = "lambdas-download/webhook.zip"
  runner_binaries_syncer_lambda_zip = "lambdas-download/runner-binaries-syncer.zip"
  runners_lambda_zip                = "lambdas-download/runners.zip"
}
