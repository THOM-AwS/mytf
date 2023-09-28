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
        Action   = "dynamodb:PutItem",
        Effect   = "Allow",
        Resource = aws_dynamodb_table.generic_data.arn
      }
    ]
  })
}
