# Lambda@Edge headers function from module v1, held here only so the
# distribution can drop its association before the function is deleted.
# Terraform otherwise tries the delete first, which CloudFront refuses
# while the function is still attached. Remove this file (and
# secheader.py) once CloudFront has cleared the replicas.

moved {
  from = module.aws-static-website.aws_lambda_function.cloudfront_lambda
  to   = aws_lambda_function.legacy_sec_headers
}

moved {
  from = module.aws-static-website.aws_iam_role.iam_for_lambda
  to   = aws_iam_role.legacy_sec_headers
}

data "archive_file" "legacy_sec_headers" {
  type        = "zip"
  source_file = "${path.module}/secheader.py"
  output_path = "${path.module}/secheader.py.zip"
}

resource "aws_iam_role" "legacy_sec_headers" {
  name                  = "website-hamer-cloud-execution_role"
  force_detach_policies = true
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = ["edgelambda.amazonaws.com", "lambda.amazonaws.com"] }
    }]
  })

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_lambda_function" "legacy_sec_headers" {
  filename      = data.archive_file.legacy_sec_headers.output_path
  function_name = "hamer-cloud-sec-headers"
  role          = aws_iam_role.legacy_sec_headers.arn
  handler       = "secheader.lambda_handler"
  runtime       = "python3.11"
  publish       = true

  lifecycle {
    ignore_changes = all
  }
}
