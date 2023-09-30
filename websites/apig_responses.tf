# ===========================================
# API Gateway Method Responses
# ===========================================

# Root Path Method Response

resource "aws_api_gateway_method_response" "root_get_200" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_rest_api.generic_api.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Content-Type" = true
  }
  response_models = {
    "application/x-www-form-urlencoded" = aws_api_gateway_model.ResponseModel.name
  }
}

# /data Path Method Responses

resource "aws_api_gateway_method_response" "data_post_200" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_method_response" "data_post_400" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status_code = "400"
  response_models = {
    "application/x-www-form-urlencoded" = "ClientErrorModel"
  }
}

resource "aws_api_gateway_method_response" "data_post_500" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status_code = "500"
  response_models = {
    "application/x-www-form-urlencoded" = aws_api_gateway_model.ServerErrorModel.name
  }
}

# ===========================================
# API Gateway Integration Responses
# ===========================================

# Root Path Integration Response

resource "aws_api_gateway_integration_response" "root_mock_200_response" {
  depends_on        = [aws_api_gateway_integration.root_mock_integration]
  rest_api_id       = aws_api_gateway_rest_api.generic_api.id
  resource_id       = aws_api_gateway_rest_api.generic_api.root_resource_id
  http_method       = aws_api_gateway_method.root_get.http_method
  status_code       = "200"
  selection_pattern = "2\\d{2}"
  response_parameters = {
    "method.response.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }
  response_templates = {
    "application/x-www-form-urlencoded" = jsonencode({
      statusCode = 200,
      message    = "Hello from your API at hamer.cloud."
    })
  }
}

# /data Path Integration Responses

resource "aws_api_gateway_integration_response" "data_post_200_response" {
  depends_on        = [aws_api_gateway_integration.ddb_integration]
  rest_api_id       = aws_api_gateway_rest_api.generic_api.id
  resource_id       = aws_api_gateway_resource.generic_resource.id
  http_method       = aws_api_gateway_method.generic_post.http_method
  status_code       = "200"
  selection_pattern = "2\\d{2}"
  response_parameters = {
    "method.response.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }
  #   response_templates = {
  #     "application/x-www-form-urlencoded" = <<-EOF
  # {
  #   "statusCode": $input.json('$.statusCode'),
  #   "message": $input.json('$.message'),
  #   "data": {
  #     "timestamp": $input.json('$.data.timestamp'),
  #     "lat": $input.json('$.data.lat'),
  #     "lon": $input.json('$.data.lon')
  #   }
  # }
  # EOF
  #   }
}

resource "aws_api_gateway_integration_response" "data_post_4XX_response" {
  depends_on        = [aws_api_gateway_integration.ddb_integration]
  rest_api_id       = aws_api_gateway_rest_api.generic_api.id
  resource_id       = aws_api_gateway_resource.generic_resource.id
  http_method       = aws_api_gateway_method.generic_post.http_method
  status_code       = "400"
  selection_pattern = "4\\d{2}"
  response_templates = {
    "application/x-www-form-urlencoded" = jsonencode({
      error   = "Bad Request",
      message = "$input.path('$.errorMessage')"
    })
  }
}

resource "aws_api_gateway_integration_response" "data_post_5XX_response" {
  depends_on        = [aws_api_gateway_integration.ddb_integration]
  rest_api_id       = aws_api_gateway_rest_api.generic_api.id
  resource_id       = aws_api_gateway_resource.generic_resource.id
  http_method       = aws_api_gateway_method.generic_post.http_method
  status_code       = "500"
  selection_pattern = "5\\d{2}"
  response_templates = {
    "application/x-www-form-urlencoded" = jsonencode({
      error   = "Unexpected Error",
      message = "$input.path('$.errorMessage')"
    })
  }
}

resource "aws_api_gateway_integration_response" "data_post_default_response" {
  rest_api_id       = aws_api_gateway_rest_api.generic_api.id
  resource_id       = aws_api_gateway_resource.generic_resource.id
  http_method       = aws_api_gateway_method.generic_post.http_method
  status_code       = "500" # Assuming you want to treat unspecified responses as 500 errors
  selection_pattern = ""

  response_templates = {
    "application/x-www-form-urlencoded" = "{\"error\": \"Unexpected Error\", \"message\": \"$input.path('$.errorMessage')\"}"
  }
}



# ===========================================
# Default API Gateway Responses
# ===========================================

resource "aws_api_gateway_gateway_response" "default_4xx_response" {
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  status_code   = "400"
  response_type = "DEFAULT_4XX"
  response_templates = {
    "application/x-www-form-urlencoded" = "{\"message\": \"$context.error.message\"}"
  }
}

resource "aws_api_gateway_gateway_response" "default_403_response" {
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  status_code   = "403"
  response_type = "ACCESS_DENIED"
  response_templates = {
    "application/x-www-form-urlencoded" = "{\"message\": \"Access Denied\"}"
  }
}

resource "aws_api_gateway_gateway_response" "default_404_response" {
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  status_code   = "404"
  response_type = "RESOURCE_NOT_FOUND"
  response_templates = {
    "application/x-www-form-urlencoded" = "{\"message\": \"Not Found\"}"
  }
}

resource "aws_api_gateway_gateway_response" "default_5xx_response" {
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  status_code   = "500"
  response_type = "DEFAULT_5XX"
  response_templates = {
    "application/x-www-form-urlencoded" = "{\"message\": \"An unexpected error occurred.\"}"
  }
}

