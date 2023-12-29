resource "aws_lambda_function" "fitbit__lambda" {
  depends_on    = [null_resource.create_zip]
  filename      = "fitbit.zip"
  function_name = "fitbit_lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "fitbit.lambda_handler"
  runtime       = "python3.11" # Change to your desired Python version
  timeout       = 60
  environment {
    variables = {
      DYNAMODB_TABLE_NAME  = "genericDataTable"
      FITBIT_CLIENT_ID     = "YOUR_FITBIT_CLIENT_ID"
      FITBIT_CLIENT_SECRET = "YOUR_FITBIT_CLIENT_SECRET"
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
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

resource "aws_iam_policy" "lambda_policy" {
  name = "fitbit_lambda_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ],
        Resource = aws_dynamodb_table.generic_data.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_exec_role.name
}

resource "null_resource" "create_zip" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command     = <<-EOT
      apk add zip
      cd fitbit_deployment
      zip -r ./* ../fitbit.zip
    EOT
    interpreter = ["/bin/sh", "-c"]
  }
}


# resource "null_resource" "wait_5_seconds" {
#   depends_on = [null_resource.create_zip]
#   triggers = {
#     always_run = "${timestamp()}"
#   }

#   provisioner "local-exec" {
#     command = "sleep 5"
#   }
# }
