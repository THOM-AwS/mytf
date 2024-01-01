resource "aws_lambda_function" "fitbit_lambda" {
  depends_on       = [null_resource.create_zip]
  filename         = "fitbit.zip"
  function_name    = "fitbit_lambda"
  role             = aws_iam_role.fitbit_lambda_exec_role.arn
  handler          = "fitbit.lambda_handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = filebase64sha256("fitbit.zip")
  environment {
    variables = {
      FITBIT_CLIENT_ID = data.aws_ssm_parameter.client_id.value
    }
  }
}

data "aws_ssm_parameter" "client_id" {
  name = "fitbit_client_id"
}

resource "aws_lambda_permission" "fitbit_get" {
  statement_id  = "AllowAPIGatewayInvokefitbit"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fitbit_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.generic_api.execution_arn}/*/*/*"
}

resource "null_resource" "create_zip" {
  triggers = {
    checksum = filebase64sha256("fitbit_deployment/fitbit.py")
  }
  provisioner "local-exec" {
    command     = <<-EOT
      apk add zip
      cd fitbit_deployment && zip -r ../fitbit.zip *
    EOT
    interpreter = ["/bin/sh", "-c"]
  }
}


# apig part

resource "aws_api_gateway_resource" "fitbit_resource" {
  depends_on  = [aws_api_gateway_rest_api.generic_api]
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  parent_id   = aws_api_gateway_rest_api.generic_api.root_resource_id
  path_part   = "fitbit"
}

resource "aws_api_gateway_integration" "fitbit_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.generic_api.id
  resource_id             = aws_api_gateway_resource.fitbit_resource.id
  http_method             = aws_api_gateway_method.fitbit_get.http_method
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.fitbit_lambda.arn}/invocations"
  type                    = "AWS_PROXY"
  timeout_milliseconds    = 20000
  credentials             = aws_iam_role.fitbit_api_gateway_role.arn
}

resource "aws_api_gateway_method" "fitbit_get" {
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  resource_id   = aws_api_gateway_resource.fitbit_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "fitbit_method_response" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.fitbit_resource.id
  http_method = aws_api_gateway_method.fitbit_get.http_method
  status_code = "200"
}
