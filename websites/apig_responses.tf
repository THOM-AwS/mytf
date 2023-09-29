# / path
resource "aws_api_gateway_integration_response" "root_mock_200_response" {
  depends_on  = [aws_api_gateway_integration.root_mock_integration]
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_rest_api.generic_api.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
    // Add other headers if necessary
  }

  response_templates = {
    "application/json" = jsonencode({
      statusCode = 200,
      message    = "Hello from your API at hamer.cloud."
    })
  }
}

# / path
resource "aws_api_gateway_method_response" "root_get_200" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_rest_api.generic_api.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
    // Add other headers if necessary
  }
  response_models = {
    "application/json" = aws_api_gateway_model.response_model.name
  }
}

# /data path
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

# / path
resource "aws_api_gateway_method_response" "generic_post_200" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}
# /data path
resource "aws_api_gateway_integration_response" "ddb_4XX_response" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status      = "400"

  response_templates = {
    "application/json" = "{\"error\": \"Client Error\"}"
  }

  selection_pattern = "4\\d{2}" # Matches any 400-series error from DynamoDB
}

# /data path
resource "aws_api_gateway_integration_response" "ddb_5XX_response" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status      = "500"

  response_templates = {
    "application/json" = "{\"error\": \"Server Error\"}"
  }

  selection_pattern = "5\\d{2}" # Matches any 500-series error from DynamoDB
}


resource "aws_api_gateway_method_response" "400_response" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status      = "400"

  response_models = {
    "application/json" = "Error"
  }
}

resource "aws_api_gateway_method_response" "500_response" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status      = "500"

  response_models = {
    "application/json" = "Error"
  }
}

resource "aws_api_gateway_gateway_response" "default_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  response_type = "DEFAULT_4XX"

  response_templates = {
    "application/json" = "{\"message\": \"$context.error.message\"}"
  }

  status = 400
}

resource "aws_api_gateway_gateway_response" "default_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  response_type = "DEFAULT_5XX"

  response_templates = {
    "application/json" = "{\"message\": \"An unexpected error occurred.\"}"
  }

  status = 500
}
