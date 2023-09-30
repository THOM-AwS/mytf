resource "aws_api_gateway_method" "generic_post" {
  depends_on    = [aws_api_gateway_resource.generic_resource]
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  resource_id   = aws_api_gateway_resource.generic_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ddb_integration" {
  depends_on  = [aws_api_gateway_method.generic_post]
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method

  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${local.workspace.aws_region}:dynamodb:action/PutItem"
  credentials             = aws_iam_role.api_gw_to_ddb.arn

  request_templates = {
    "application/x-www-form-urlencoded" = <<-EOF
{
   "TableName": "YourTableName",
   "Item": {
       "yourPrimaryKeyAttributeName": {
           "S": "$input.path('$.yourPrimaryKeyAttribute')"
       },
       "lon": {
           "N": "$input.path('$.lon')"
       },
       "lat": {
           "N": "$input.path('$.lat')"
       },
       "timestamp": {
           "N": "$input.path('$.timestamp')"
       }
   }
}
EOF
  }
}

resource "aws_api_gateway_method" "root_get" {
  depends_on    = [aws_api_gateway_rest_api.generic_api]
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  resource_id   = aws_api_gateway_rest_api.generic_api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_mock_integration" {
  depends_on  = [aws_api_gateway_method.root_get]
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_rest_api.generic_api.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method

  type = "MOCK"

  request_templates = {
    "application/x-www-form-urlencoded" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}
