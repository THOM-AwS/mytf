resource "aws_api_gateway_model" "response_model" {
  rest_api_id  = aws_api_gateway_rest_api.generic_api.id
  name         = "ResponseModel"
  content_type = "application/json"
  schema = jsonencode({
    title = "ResponseModel",
    type  = "object",
    properties = {
      message = {
        type = "string"
      }
    }
  })
}
