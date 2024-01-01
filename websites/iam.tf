resource "aws_iam_role" "api_gw_to_ddb" {
  name = "ApiGatewayToDynamoDBRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gw_ddb_access" {
  name = "ApiGatewayDynamoDBAccess"
  role = aws_iam_role.api_gw_to_ddb.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Effect   = "Allow",
        Resource = "*" #aws_dynamodb_table.generic_data.arn
      }
    ]
  })
}


resource "aws_iam_role" "apigw_cloudwatch_logging_role" {
  name = "APIGWCWLoggingRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "apigw_cloudwatch_logging_policy" {
  name = "APIGWCWLoggingPolicy"
  role = aws_iam_role.apigw_cloudwatch_logging_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "logs:CreateLogGroup",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
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
        "Service": [
          "lambda.amazonaws.com",
          "apigateway.amazonaws.com"
          ]
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
          "ssm:GetParameter",
          "ssm:PutParameter"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction"
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

resource "aws_iam_role" "fitbit_api_gateway_role" {
  name = "fitbit-api-gateway-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

data "aws_iam_policy" "lamda_logs" {
  name = "AWSLambdaRole"
}

data "aws_iam_policy" "lambda_execute" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy_attachment" "fitbit_api_gateway_policy_attachment" {
  name       = "fitbit-api-gateway-lambda-role"
  policy_arn = data.aws_iam_policy.lamda_logs.arn
  roles      = [aws_iam_role.fitbit_api_gateway_role.name]
}

resource "aws_iam_policy_attachment" "fitbit_api_gateway_lambda_basic_execution" {
  name       = "fitbit-api-gateway-lambda-basic-execution"
  policy_arn = data.aws_iam_policy.lambda_execute.arn
  roles      = [aws_iam_role.fitbit_api_gateway_role.name]
}
