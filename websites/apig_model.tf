resource "aws_api_gateway_model" "ResponseModel" {
  rest_api_id  = aws_api_gateway_rest_api.generic_api.id
  name         = "ResponseModel"
  content_type = "application/json"
  schema = jsonencode({
    title = "ResponseModel",
    type  = "object",
    properties = {
      status = {
        type    = "string",
        default = "Success"
      },
      code = {
        type    = "integer",
        default = 200
      },
      message = {
        type = "string"
      },
      details = {
        type = "string"
      }
    },
    required = ["status", "code", "message"]
  })
}

resource "aws_api_gateway_model" "ClientErrorModel" {
  rest_api_id  = aws_api_gateway_rest_api.generic_api.id
  name         = "ClientErrorModel"
  content_type = "application/json"
  schema = jsonencode({
    title = "ClientErrorModel",
    type  = "object",
    properties = {
      status = {
        type    = "string",
        default = "Error",
        enum    = ["Error"]
      },
      code = {
        type    = "integer",
        default = 400
      },
      message = {
        type = "string"
      },
      details = {
        type = "string"
      }
    },
    required = ["status", "code", "message"]
  })
}

resource "aws_api_gateway_model" "ServerErrorModel" {
  rest_api_id  = aws_api_gateway_rest_api.generic_api.id
  name         = "ServerErrorModel"
  content_type = "application/json"
  schema = jsonencode({
    title = "ServerErrorModel",
    type  = "object",
    properties = {
      status = {
        type    = "string",
        default = "Error",
        enum    = ["Error"]
      },
      code = {
        type    = "integer",
        default = 500
      },
      message = {
        type = "string"
      },
      details = {
        type = "string"
      }
    },
    required = ["status", "code", "message"]
  })
}
