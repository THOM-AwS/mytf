resource "aws_api_gateway_integration" "ddb_integration" {
  depends_on              = [aws_api_gateway_method.generic_post]
  rest_api_id             = aws_api_gateway_rest_api.generic_api.id
  resource_id             = aws_api_gateway_resource.generic_resource.id
  http_method             = aws_api_gateway_method.generic_post.http_method
  passthrough_behavior    = "NEVER"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.log_payload.arn}/invocations"
  # credentials = aws_lambda_permission.apigw.arn
  type = "AWS_PROXY"
}

resource "aws_api_gateway_method" "generic_post" {
  depends_on    = [aws_api_gateway_resource.generic_resource]
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  resource_id   = aws_api_gateway_resource.generic_resource.id
  http_method   = "POST"
  authorization = "NONE"
  request_parameters = {
    "method.request.header.Content-Type" = true
  }
}
