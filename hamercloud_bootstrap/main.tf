# GitHub Actions roles for THOM-AwS/hamercloud (hamer.cloud site + api.hamer.cloud).
#
# CI cannot create the roles it runs as, so this stack is applied by mytf's own
# pipeline (static admin keys) once, then the code moves to hamercloud
# infra/bootstrap with the same state key. Modelled on qwen-spot's bootstrap.
#
# Three roles, all trusting the repo's immutable OIDC subject:
#   hamercloud-github-plan   read-only, any branch push, plans with -lock=false
#   hamercloud-github-apply  terraform apply, only via the hamercloud-infra environment
#   hamercloud-github-site   S3 sync + CloudFront invalidation, only via hamercloud-site
#
# This is the management account. Everything is scoped to this stack's named
# resources; nothing here can reach other stacks' state, buckets or roles.

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "hamer-terraform-backend"
    key          = "hamercloud/bootstrap.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project = "hamercloud"
      Stack   = "bootstrap"
    }
  }
}

variable "github_sub_prefix" {
  description = <<-EOT
    Immutable OIDC subject prefix for THOM-AwS/hamercloud, so a renamed or
    re-registered repo cannot take over the roles. The repo must have
    use_immutable_subject enabled for tokens to carry this form:
    gh api repos/THOM-AwS/hamercloud/actions/oidc/customization/sub
  EOT
  type        = string
  default     = "repo:THOM-AwS@48810100/hamercloud@407606161"

  validation {
    condition     = can(regex("^repo:[A-Za-z0-9-]+@[0-9]+/[A-Za-z0-9._-]+@[0-9]+$", var.github_sub_prefix))
    error_message = "github_sub_prefix must be the immutable form repo:<owner>@<id>/<repo>@<id>."
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  iam_arn    = "arn:aws:iam::${local.account_id}"
  region     = "us-east-1"

  state_bucket = "hamer-terraform-backend"
  state_key    = "env:/hamer/tf-hamer/hamer-website"
  lock_table   = "arn:aws:dynamodb:ap-southeast-2:${local.account_id}:table/hamer-terraform-lock"
  # The S3 backend's lock row and state digest row.
  lock_keys = ["${local.state_bucket}/${local.state_key}", "${local.state_bucket}/${local.state_key}-md5"]
  # Workspace listing uses prefix "env:/"; state lives under env:/hamer/.
  state_prefixes = ["env:/", "env:/hamer/tf-hamer/*"]

  distribution_id = "E3EZ46MUZPKKIB"
  oac_id          = "E1UBXIX50M958W"
  oai_id          = "E4XB766TKAB6L"
  hosted_zone_id  = "Z01871282UNAOFQSTNCVD"
  rest_api_id     = "nnsw0xovm4"
  api_domain      = "api.hamer.cloud"

  site_buckets = ["hamer.cloud", "www.hamer.cloud", "hamer.cloud-logging"]

  # Existing roles, policies and user the main stack manages. Their names
  # predate any prefix, so they are listed explicitly; new ones use hamercloud-*.
  stack_role_names = [
    "LambdaLoggingRole",
    "ApiGatewayToDynamoDBRole",
    "APIGWCWLoggingRole",
    "fitbit_fetch_role",
    "fitbit_api_role",
    "website-hamer-cloud-execution_role",
  ]
  stack_policy_names = ["LambdaDynamoDBAccess", "fitbit_fetch_policy", "fitbit_api_policy"]
  site_user_name     = "website-hamer-cloud-user"

  function_names = ["get_loc_Lambda", "LogPayloadLambda", "fitbit_fetch", "fitbit_api", "hamer-cloud-sec-headers"]
  table_names    = ["genericDataTable", "WebSiteCache", "fitbitData"]

  stack_role_arns   = concat([for n in local.stack_role_names : "${local.iam_arn}:role/${n}"], ["${local.iam_arn}:role/hamercloud-*"])
  stack_policy_arns = concat([for n in local.stack_policy_names : "${local.iam_arn}:policy/${n}"], ["${local.iam_arn}:policy/hamercloud-*"])
  site_user_arn     = "${local.iam_arn}:user/website-users/${local.site_user_name}"

  function_arns = flatten([for n in local.function_names : [
    "arn:aws:lambda:${local.region}:${local.account_id}:function:${n}",
    "arn:aws:lambda:${local.region}:${local.account_id}:function:${n}:*",
  ]])
  table_arns = flatten([for n in local.table_names : [
    "arn:aws:dynamodb:${local.region}:${local.account_id}:table/${n}",
    "arn:aws:dynamodb:${local.region}:${local.account_id}:table/${n}/*",
  ]])
  bucket_arns     = flatten([for b in local.site_buckets : ["arn:aws:s3:::${b}", "arn:aws:s3:::${b}/*"]])
  distribution    = "arn:aws:cloudfront::${local.account_id}:distribution/${local.distribution_id}"
  cloudfront_arns = [local.distribution, "arn:aws:cloudfront::${local.account_id}:origin-access-control/${local.oac_id}", "arn:aws:cloudfront::${local.account_id}:origin-access-identity/${local.oai_id}"]
  apigw_arns = [
    "arn:aws:apigateway:${local.region}::/restapis/${local.rest_api_id}",
    "arn:aws:apigateway:${local.region}::/restapis/${local.rest_api_id}/*",
    "arn:aws:apigateway:${local.region}::/domainnames/${local.api_domain}",
    "arn:aws:apigateway:${local.region}::/domainnames/${local.api_domain}/*",
    "arn:aws:apigateway:${local.region}::/account",
    "arn:aws:apigateway:${local.region}::/tags/*",
  ]
  log_group_arns = [
    "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/apigateway/GenericAPI",
    "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/apigateway/GenericAPI:*",
  ]
  event_rule_arn = "arn:aws:events:${local.region}:${local.account_id}:rule/fitbit-fetch-schedule"
  alarm_arn      = "arn:aws:cloudwatch:${local.region}:${local.account_id}:alarm:fitbit-token-refresh-failure"

  apply_role_arn = "${local.iam_arn}:role/hamercloud-github-apply"
  plan_role_arn  = "${local.iam_arn}:role/hamercloud-github-plan"
  site_role_arn  = "${local.iam_arn}:role/hamercloud-github-site"
  boundary_arn   = "${local.iam_arn}:policy/hamercloud-boundary"
}

# ---- trust --------------------------------------------------------------------

data "aws_iam_policy_document" "trust" {
  for_each = {
    apply = { test = "StringEquals", sub = "${var.github_sub_prefix}:environment:hamercloud-infra" }
    site  = { test = "StringEquals", sub = "${var.github_sub_prefix}:environment:hamercloud-site" }
    # Branch pushes only. Environment jobs and pull requests get other subjects.
    plan = { test = "StringLike", sub = "${var.github_sub_prefix}:ref:refs/heads/*" }
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = each.value.test
      variable = "token.actions.githubusercontent.com:sub"
      values   = [each.value.sub]
    }
  }
}

# ---- permissions boundary -------------------------------------------------------
# Caps every role the main stack runs (Lambdas, API Gateway integrations). New
# hamercloud-* roles must carry it, and CI can only edit a role's policies while
# the role carries it, so no policy edit can lift a workload role past this.

data "aws_iam_policy_document" "boundary" {
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams", "logs:GetLogEvents", "logs:FilterLogEvents"]
    resources = ["arn:aws:logs:*:${local.account_id}:*"]
  }

  statement {
    sid       = "Tables"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:BatchWriteItem", "dynamodb:DescribeTable"]
    resources = local.table_arns
  }

  # Fitbit tokens and client credentials. The fetch Lambda keeps tokens in
  # access_token / refresh_token at the parameter root.
  statement {
    sid     = "FitbitParameters"
    actions = ["ssm:GetParameter", "ssm:PutParameter"]
    resources = [for n in ["fitbit_client_id", "fitbit_client_secret", "access_token", "refresh_token"] :
    "arn:aws:ssm:${local.region}:${local.account_id}:parameter/${n}"]
  }

  # For when the Fitbit parameters become SecureString (AWS managed SSM key).
  statement {
    sid       = "SsmKeyViaSsm"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
    resources = ["arn:aws:kms:${local.region}:${local.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${local.region}.amazonaws.com"]
    }
  }

  statement {
    sid       = "InvokeStackFunctions"
    actions   = ["lambda:InvokeFunction"]
    resources = local.function_arns
  }

  statement {
    sid       = "Metrics"
    actions   = ["cloudwatch:PutMetricData", "xray:PutTraceSegments", "xray:PutTelemetryRecords"]
    resources = ["*"]
  }

  statement {
    sid       = "NeverEscalate"
    effect    = "Deny"
    actions   = ["iam:*", "organizations:*", "account:*", "sso:*", "sts:AssumeRole"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "boundary" {
  name        = "hamercloud-boundary"
  description = "Permissions boundary for every role the hamercloud stack runs"
  policy      = data.aws_iam_policy_document.boundary.json
}

# ---- apply role -----------------------------------------------------------------

resource "aws_iam_role" "apply" {
  name                 = "hamercloud-github-apply"
  description          = "Terraform apply for THOM-AwS/hamercloud infra (hamercloud-infra environment)"
  assume_role_policy   = data.aws_iam_policy_document.trust["apply"].json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "apply_iam" {
  # No iam:CreateRole: a new role's trust policy cannot be constrained by IAM
  # conditions, so CI could make one trust an outside account. New roles are
  # added here, in bootstrap, instead.

  statement {
    sid       = "SetBoundary"
    actions   = ["iam:PutRolePermissionsBoundary"]
    resources = local.stack_role_arns

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [local.boundary_arn]
    }
  }

  # Policy edits only on roles that already carry the boundary. Until the main
  # stack sets it on the existing roles, their policies are frozen.
  statement {
    sid       = "EditBoundedRoles"
    actions   = ["iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:AttachRolePolicy", "iam:DetachRolePolicy"]
    resources = local.stack_role_arns

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [local.boundary_arn]
    }
  }

  statement {
    sid       = "RoleMetadata"
    actions   = ["iam:UpdateRole", "iam:UpdateRoleDescription", "iam:TagRole", "iam:UntagRole", "iam:DeleteRole"]
    resources = local.stack_role_arns
  }

  # Managed policy versions are safe only because every role they can be
  # attached to carries the boundary (attach and edit both require it), so a
  # widened policy still cannot exceed the boundary.
  statement {
    sid = "StackPolicies"
    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = local.stack_policy_arns
  }

  # The module's deploy user can only be read or removed. Granting it a policy
  # or a new key would give an unbounded human-style principal.
  statement {
    sid = "RemoveSiteUser"
    actions = [
      "iam:DeleteUser",
      "iam:DeleteAccessKey",
      "iam:DeleteUserPolicy",
      "iam:DetachUserPolicy",
      "iam:TagUser",
      "iam:UntagUser",
    ]
    resources = [local.site_user_arn]
  }

  statement {
    sid       = "PassStackRoles"
    actions   = ["iam:PassRole"]
    resources = local.stack_role_arns

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com", "apigateway.amazonaws.com"]
    }
  }

  statement {
    sid       = "EdgeReplicatorRole"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["replicator.lambda.amazonaws.com", "logger.cloudfront.amazonaws.com"]
    }
  }

  statement {
    sid       = "ReadIam"
    actions   = ["iam:Get*", "iam:List*"]
    resources = ["*"]
  }

  statement {
    sid         = "DenyTouchingCiRoles"
    effect      = "Deny"
    not_actions = ["iam:Get*", "iam:List*"]
    resources   = [local.apply_role_arn, local.plan_role_arn, local.site_role_arn]
  }

  statement {
    sid    = "DenyEditingBoundary"
    effect = "Deny"
    actions = [
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:DeletePolicy",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = [local.boundary_arn]
  }

  # Trust changes go through this stack only, or CI could make a role trust an
  # outside account.
  statement {
    sid       = "DenyTrustAndBoundaryRemoval"
    effect    = "Deny"
    actions   = ["iam:UpdateAssumeRolePolicy", "iam:DeleteRolePermissionsBoundary"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "apply_iam" {
  name   = "hamercloud-iam-scoped"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply_iam.json
}

data "aws_iam_policy_document" "apply_services" {
  statement {
    sid       = "SiteBuckets"
    actions   = ["s3:*"]
    resources = local.bucket_arns
  }

  statement {
    sid       = "CloudFront"
    actions   = ["cloudfront:*"]
    resources = local.cloudfront_arns
  }

  # Managed cache and origin request policy lookups, and the bucket list.
  statement {
    sid       = "CloudFrontReads"
    actions   = ["cloudfront:Get*", "cloudfront:List*", "cloudfront:Describe*"]
    resources = ["*"]
  }

  statement {
    sid       = "Functions"
    actions   = ["lambda:*"]
    resources = local.function_arns
  }

  statement {
    sid       = "ApiGateway"
    actions   = ["apigateway:*"]
    resources = local.apigw_arns
  }

  statement {
    sid       = "ApiGatewayLists"
    actions   = ["apigateway:GET"]
    resources = ["arn:aws:apigateway:${local.region}::/restapis", "arn:aws:apigateway:${local.region}::/domainnames"]
  }

  statement {
    sid       = "Tables"
    actions   = ["dynamodb:*"]
    resources = local.table_arns
  }

  statement {
    sid       = "Schedule"
    actions   = ["events:*"]
    resources = [local.event_rule_arn]
  }

  statement {
    sid       = "Alarm"
    actions   = ["cloudwatch:*"]
    resources = [local.alarm_arn]
  }

  statement {
    sid       = "LogGroup"
    actions   = ["logs:*"]
    resources = local.log_group_arns
  }

  statement {
    sid       = "Dns"
    actions   = ["route53:ChangeResourceRecordSets", "route53:GetHostedZone", "route53:ListResourceRecordSets", "route53:ListTagsForResource"]
    resources = ["arn:aws:route53:::hostedzone/${local.hosted_zone_id}"]
  }

  statement {
    sid = "AccountWideReads"
    actions = [
      "sts:GetCallerIdentity",
      "s3:ListAllMyBuckets",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "acm:GetCertificate",
      "acm:ListTagsForCertificate",
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
      "route53:GetChange",
      "logs:DescribeLogGroups",
      "cloudwatch:DescribeAlarms",
      "events:DescribeRule",
      "events:ListTargetsByRule",
      "dynamodb:ListTables",
      "lambda:ListFunctions",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "StateObject"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${local.state_bucket}/${local.state_key}"]
  }

  statement {
    sid       = "StateList"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.state_bucket}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = local.state_prefixes
    }
  }

  # DynamoDB locking (shared with mytf until websites/ is retired there). Only
  # this stack's lock and digest rows.
  statement {
    sid       = "StateLock"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [local.lock_table]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "dynamodb:LeadingKeys"
      values   = local.lock_keys
    }
  }

  statement {
    sid       = "DenyOrgAndCrossAccount"
    effect    = "Deny"
    actions   = ["sts:AssumeRole", "organizations:*", "account:*", "sso:*", "sso-directory:*", "identitystore:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "apply_services" {
  name   = "hamercloud-services"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply_services.json
}

# ---- plan role (read-only) ----------------------------------------------------
# Every branch push can use this role without approval, so it can only read this
# stack's configuration and state, and the apply role can never widen it.

resource "aws_iam_role" "plan" {
  name                 = "hamercloud-github-plan"
  description          = "Read-only terraform plan for THOM-AwS/hamercloud infra"
  assume_role_policy   = data.aws_iam_policy_document.trust["plan"].json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "plan_read" {
  statement {
    sid       = "StateRead"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.state_bucket}/${local.state_key}"]
  }

  statement {
    sid       = "StateList"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.state_bucket}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = local.state_prefixes
    }
  }

  # -lock=false skips the lock, but the S3 backend still reads the digest row.
  statement {
    sid       = "StateDigestRead"
    actions   = ["dynamodb:GetItem"]
    resources = [local.lock_table]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "dynamodb:LeadingKeys"
      values   = local.lock_keys
    }
  }

  statement {
    sid       = "StackIamRead"
    actions   = ["iam:Get*", "iam:List*"]
    resources = concat(local.stack_role_arns, local.stack_policy_arns, [local.site_user_arn, "arn:aws:iam::aws:policy/*"])
  }

  # Bucket configuration only; object reads are denied below.
  statement {
    sid       = "SiteBucketConfig"
    actions   = ["s3:ListBucket", "s3:GetBucket*", "s3:GetAccelerateConfiguration", "s3:GetLifecycleConfiguration", "s3:GetReplicationConfiguration", "s3:GetEncryptionConfiguration"]
    resources = [for b in local.site_buckets : "arn:aws:s3:::${b}"]
  }

  statement {
    sid       = "CloudFrontReads"
    actions   = ["cloudfront:Get*", "cloudfront:List*", "cloudfront:Describe*"]
    resources = ["*"]
  }

  statement {
    sid       = "FunctionReads"
    actions   = ["lambda:Get*", "lambda:List*"]
    resources = local.function_arns
  }

  statement {
    sid       = "ApiGatewayReads"
    actions   = ["apigateway:GET"]
    resources = concat(local.apigw_arns, ["arn:aws:apigateway:${local.region}::/restapis", "arn:aws:apigateway:${local.region}::/domainnames"])
  }

  statement {
    sid       = "TableReads"
    actions   = ["dynamodb:Describe*", "dynamodb:ListTagsOfResource"]
    resources = local.table_arns
  }

  statement {
    sid       = "ScheduleReads"
    actions   = ["events:DescribeRule", "events:ListTargetsByRule", "events:ListTagsForResource"]
    resources = [local.event_rule_arn]
  }

  statement {
    sid       = "AlarmReads"
    actions   = ["cloudwatch:DescribeAlarms", "cloudwatch:ListTagsForResource"]
    resources = ["*"]
  }

  statement {
    sid       = "LogGroupReads"
    actions   = ["logs:DescribeLogGroups", "logs:ListTagsForResource", "logs:ListTagsLogGroup"]
    resources = concat(local.log_group_arns, ["arn:aws:logs:${local.region}:${local.account_id}:log-group:*"])
  }

  statement {
    sid       = "DnsReads"
    actions   = ["route53:GetHostedZone", "route53:ListResourceRecordSets", "route53:ListTagsForResource", "route53:ListHostedZones", "route53:ListHostedZonesByName"]
    resources = ["*"]
  }

  statement {
    sid       = "AccountWideReads"
    actions   = ["sts:GetCallerIdentity", "acm:ListCertificates", "acm:DescribeCertificate", "acm:ListTagsForCertificate"]
    resources = ["*"]
  }

  statement {
    sid       = "NeverWriteOrAssume"
    effect    = "Deny"
    actions   = ["sts:AssumeRole", "s3:GetObject*", "s3:PutObject*", "s3:DeleteObject*"]
    resources = concat([for b in local.site_buckets : "arn:aws:s3:::${b}/*"], ["arn:aws:iam::*:role/*"])
  }
}

resource "aws_iam_role_policy" "plan_read" {
  name   = "hamercloud-plan-read"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_read.json
}

# ---- site deploy role -----------------------------------------------------------

resource "aws_iam_role" "site" {
  name                 = "hamercloud-github-site"
  description          = "S3 sync and CloudFront invalidation for hamer.cloud (hamercloud-site environment)"
  assume_role_policy   = data.aws_iam_policy_document.trust["site"].json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "site_deploy" {
  statement {
    sid       = "ListSiteBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::www.hamer.cloud"]
  }

  statement {
    sid       = "SyncSiteObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::www.hamer.cloud/*"]
  }

  statement {
    sid       = "Invalidate"
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation", "cloudfront:ListInvalidations"]
    resources = [local.distribution]
  }
}

resource "aws_iam_role_policy" "site_deploy" {
  name   = "hamercloud-site-deploy"
  role   = aws_iam_role.site.id
  policy = data.aws_iam_policy_document.site_deploy.json
}

output "apply_role_arn" {
  description = "Role for the hamercloud-infra environment's apply job."
  value       = aws_iam_role.apply.arn
}

output "plan_role_arn" {
  description = "Role for the read-only plan job."
  value       = aws_iam_role.plan.arn
}

output "site_role_arn" {
  description = "Role for the hamercloud-site environment's deploy job."
  value       = aws_iam_role.site.arn
}

output "permissions_boundary_arn" {
  description = "Boundary every role the main stack runs must carry."
  value       = aws_iam_policy.boundary.arn
}
