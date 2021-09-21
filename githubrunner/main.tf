
module "github-runner_runners" {
  source  = "philips-labs/github-runner/aws//modules/runners"
  version = "0.18.1"

  aws_region = local.workspace["aws_region"]
  vpc_id     = local.workspace["vpc_id"]
  subnet_ids = local.workspace["subnet_ids"]

  environment = local.workspace["environment"]

  github_app_parameters = {
    key_base64     = local.workspace["key_base64"]
    id             = local.workspace["id"]
    client_id      = local.workspace["client_id"]
    client_secret  = local.workspace["client_secret"]
    webhook_secret = local.workspace["webhook_secret"]
  }
  create_service_linked_role_spot   = true
  enable_ssm_on_runners             = true
  instance_types                    = "t2.small"
  sqs_build_queue                   = aws_sqs_queue.runner-queue.name
  runner_iam_role_managed_policy_arns = "arn:aws:iam::490638925706:role/SSMInstanceProfile"
  webhook_lambda_zip                = "lambdas-download/webhook.zip"
  runner_binaries_syncer_lambda_zip = "lambdas-download/runner-binaries-syncer.zip"
  runners_lambda_zip                = "lambdas-download/runners.zip"
}

resource "aws_sqs_queue" "runner-queue" {
  name                      = "runner-queue"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
    maxReceiveCount     = 4
  })

  tags = {
    Environment = "prod"
  }
}

resource "aws_sqs_queue" "terraform_queue_deadletter" {
  name                      = "deadletter-queue"
  tags = {
    Environment = "prod"
  }
}