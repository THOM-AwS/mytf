data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "generic_api" {
  name        = "GenericAPI"
  description = "API to store generic data."
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "generic_resource" {
  depends_on  = [aws_api_gateway_rest_api.generic_api]
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  parent_id   = aws_api_gateway_rest_api.generic_api.root_resource_id
  path_part   = "data"
}

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
    "application/json" = <<-TEMPLATE
      {
        "TableName": "genericDataTable",
        "Item": {
          "timestamp": { "S": "$input.path('$.timestamp')" },
          "lat": { "S": "$input.path('$.lat')" },
          "lon": { "S": "$input.path('$.lon')" }
        }
      }
    TEMPLATE
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
}

resource "aws_api_gateway_deployment" "deploy_api" {
  depends_on = [
    aws_api_gateway_rest_api.generic_api,
    aws_api_gateway_integration.ddb_integration,
    aws_api_gateway_integration_response.ddb_200_response,
    aws_api_gateway_integration_response.root_mock_200_response
  ]
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  stage_name  = "prod"
}


resource "aws_api_gateway_domain_name" "api_custom_domain" {
  domain_name              = "api.hamer.cloud"
  regional_certificate_arn = "arn:aws:acm:us-east-1:${data.aws_caller_identity.current.account_id}:certificate/7bba1b38-d28c-4665-aa2d-456785dc1b76"
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "api_base_path_mapping" {
  depends_on  = [aws_api_gateway_deployment.deploy_api]
  api_id      = aws_api_gateway_rest_api.generic_api.id
  stage_name  = aws_api_gateway_deployment.deploy_api.stage_name
  domain_name = aws_api_gateway_domain_name.api_custom_domain.domain_name
}

# Base return path
resource "aws_api_gateway_integration_response" "root_mock_200_response" {
  depends_on  = [aws_api_gateway_integration.root_mock_integration]
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_rest_api.generic_api.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }

  response_templates = {
    "application/json" = jsonencode({
      statusCode = 200,
      message    = "Hello from Thomas."
    })
  }
}

resource "aws_api_gateway_method_response" "root_get_200" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_rest_api.generic_api.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
    // Add other headers if necessary
  }
}


# DDB return path
resource "aws_api_gateway_integration_response" "ddb_200_response" {
  depends_on  = [aws_api_gateway_integration.ddb_integration]
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }

  response_templates = {
    "application/json" = <<-EOF
{
  "statusCode": $input.json('$.statusCode'),
  "message": $input.json('$.message'),
  "data": {
    "timestamp": $input.json('$.data.timestamp'),
    "lat": $input.json('$.data.lat'),
    "lon": $input.json('$.data.lon')
  }
}
EOF
  }
}

resource "aws_api_gateway_method_response" "generic_post_200" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}
