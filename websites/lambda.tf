resource "aws_iam_role" "lambda_logging" {
  name = "LambdaLoggingRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_logging.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "log_payload" {
  depends_on    = [null_resource.zip_lambda]
  function_name = "LogPayloadLambda"

  # Assuming you have a deployment package named "lambda_package.zip" in the current directory.
  filename = "lambda_package.zip"

  source_code_hash = filebase64sha256("lambda_package.zip")

  role    = aws_iam_role.lambda_logging.arn
  handler = "lambda.handler"
  runtime = "python3.7"

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}

resource "null_resource" "zip_lambda" {
  triggers = {
    lambda_hash = filemd5("lambda.py")
  }
  provisioner "local-exec" {
    command = "apk add --no-cache zip && zip -r lambda_package.zip lambda.py"
  }
}

# resource "aws_lambda_permission" "apigw" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.log_payload.function_name
#   principal     = "apigateway.amazonaws.com"
#   # The /*/* in the source_arn is a wildcard that can be used to allow any method on any resource within the API Gateway.
#   # Adjust the wildcard pattern as needed to be more specific if necessary.
#   source_arn = "${aws_api_gateway_deployment.deploy_api.execution_arn}/*/*"
# }




