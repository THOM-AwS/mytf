
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
