resource "aws_api_gateway_model" "UnifiedResponseModel" {
  rest_api_id  = aws_api_gateway_rest_api.generic_api.id
  name         = "UnifiedResponseModel"
  content_type = "application/json"
  schema = jsonencode({
    type = "object",
    properties = {
      statusCode = {
        type = "integer"
      },
      message = {
        type = "string"
      }
    }
  })
}

resource "aws_api_gateway_model" "location_data" {
  rest_api_id  = aws_api_gateway_rest_api.generic_api.id
  name         = "inputModel"
  content_type = "application/x-www-form-urlencoded"
  description  = "Model for capturing URL-encoded longitude, latitude, and timestamp"
  schema       = "{}"
}
