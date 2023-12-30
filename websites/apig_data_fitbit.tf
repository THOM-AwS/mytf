resource "aws_lambda_function" "fitbit_lambda" {
  depends_on    = [null_resource.create_zip]
  filename      = "fitbit.zip"
  function_name = "fitbit_lambda"
  role          = aws_iam_role.fitbit_lambda_exec_role.arn
  handler       = "fitbit.lambda_handler"
  runtime       = "python3.11"
  environment {
    variables = {
      FITBIT_CLIENT_ID     = data.aws_ssm_parameter.client_id.value
      FITBIT_CLIENT_SECRET = data.aws_ssm_parameter.client_secret.value
    }
  }
}

data "aws_ssm_parameter" "client_id" {
  name = "fitbit_client_id"
}

data "aws_ssm_parameter" "client_secret" {
  name = "fitbit_client_secret"
}

resource "aws_iam_role" "fitbit_lambda_exec_role" {
  name = "fitbit_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "fitbit_lambda_policy" {
  name = "fitbit_lambda_ssm_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "fitbit_lambda_attach" {
  policy_arn = aws_iam_policy.fitbit_lambda_policy.arn
  role       = aws_iam_role.fitbit_lambda_exec_role.name
}

resource "null_resource" "create_zip" {
  triggers = {
    always_run = "${timestamp()}"
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
resource "aws_api_gateway_integration" "fitbit_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.generic_api.id
  resource_id             = aws_api_gateway_resource.generic_resource.id
  http_method             = aws_api_gateway_method.fitbit_get.http_method
  passthrough_behavior    = "NEVER"
  integration_http_method = "GET"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.fitbit_lambda.arn}/invocations"
  type                    = "AWS_PROXY"

}

resource "aws_api_gateway_method" "fitbit_get" {
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  resource_id   = aws_api_gateway_resource.generic_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "fitbit_method_response" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.fitbit_get.http_method
  status_code = "200"
}

# resource "aws_api_gateway_integration_response" "fitbit_integration_response" {
#   rest_api_id = aws_api_gateway_rest_api.generic_api.id
#   resource_id = aws_api_gateway_resource.generic_resource.id
#   http_method = aws_api_gateway_method.fitbit_get.http_method
#   status_code = aws_api_gateway_method_response.method_response.status_code

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Origin" = "'*'"
#   }
# }
