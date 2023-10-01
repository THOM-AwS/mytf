resource "aws_api_gateway_integration" "root_mock_integration" {
  depends_on  = [aws_api_gateway_method.root_get]
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_rest_api.generic_api.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method" "generic_post" {
  depends_on    = [aws_api_gateway_resource.generic_resource]
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  resource_id   = aws_api_gateway_resource.generic_resource.id
  http_method   = "POST"
  authorization = "NONE"
  request_parameters = {
    "method.request.header.Content-Type"   = true
    "method.request.querystring.lat"       = true
    "method.request.querystring.lon"       = true
    "method.request.querystring.timestamp" = true
  }
  request_models = {
    "application/x-www-form-urlencoded" = "UnifiedResponseModel",
    "application/json"                  = "UnifiedResponseModel"
  }
}
resource "aws_api_gateway_method" "root_get" {
  depends_on    = [aws_api_gateway_rest_api.generic_api]
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  resource_id   = aws_api_gateway_rest_api.generic_api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "root_get_200" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_rest_api.generic_api.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Content-Type" = true
  }
  response_models = {
    "application/json" = "UnifiedResponseModel"
  }
}
resource "aws_api_gateway_method_response" "data_post_200" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Content-Type" = true
  }
  response_models = {
    "application/json" = "UnifiedResponseModel"
  }
}
resource "aws_api_gateway_integration_response" "root_mock_200_response" {
  depends_on        = [aws_api_gateway_integration.root_mock_integration]
  rest_api_id       = aws_api_gateway_rest_api.generic_api.id
  resource_id       = aws_api_gateway_rest_api.generic_api.root_resource_id
  http_method       = aws_api_gateway_method.root_get.http_method
  status_code       = "200"
  selection_pattern = "2\\d{2}"
  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }
  response_templates = {
    "application/json" = jsonencode({
      statusCode = 200,
      message    = "Hello from your API at hamer.cloud."
    })
  }
}
