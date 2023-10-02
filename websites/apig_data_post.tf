resource "aws_api_gateway_integration" "ddb_integration" {
  depends_on           = [aws_api_gateway_method.generic_post]
  rest_api_id          = aws_api_gateway_rest_api.generic_api.id
  resource_id          = aws_api_gateway_resource.generic_resource.id
  http_method          = aws_api_gateway_method.generic_post.http_method
  passthrough_behavior = "WHEN_NO_MATCH"
  # content_handling        = "CONVERT_TO_TEXT"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${local.workspace.aws_region}:dynamodb:action/PutItem"
  credentials             = aws_iam_role.api_gw_to_ddb.arn
  type                    = "AWS"

  request_templates = {
    "application/json" = <<-EOF
#set($decoded = $util.urlDecode($input.body))
#set($params = {})
#foreach($param in $decoded.split("&"))
    #set($keyValue = $param.split("="))
    #set($params[$keyValue[0]] = $keyValue[1])
#end

{
    "TableName": "${aws_dynamodb_table.generic_data.name}",
    "Item": {
        "longitude": {
            "N": "$params.lon"
        },
        "latitude": {
            "N": "$params.lat"
        },
        "timestamp": {
            "S": "$params.timestamp"
        }
    }
},
  "debug": {
        "timestamp": "$params.timestamp",
        "decoded_lon": "$params.lon",
        "decoded_lat": "$params.lat",
        "decoded_body": $util.escapeJavaScript($decoded),
        "request": {
            "parameters": "$util.escapeJavaScript($input.params())"
        }
    }
}
EOF
  }
}


resource "aws_api_gateway_method" "generic_post" {
  depends_on    = [aws_api_gateway_resource.generic_resource]
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  resource_id   = aws_api_gateway_resource.generic_resource.id
  http_method   = "POST"
  authorization = "NONE"
  request_parameters = {
    "method.request.header.Content-Type" = false
  }
  request_models = {
    "application/x-www-form-urlencoded" = aws_api_gateway_model.location_data.name
  }
}

resource "aws_api_gateway_method_response" "data_post_400" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status_code = "400"
  response_parameters = {
    "method.response.header.Content-Type" = true
  }
  response_models = {
    "application/json" = "UnifiedResponseModel"
  }
}

resource "aws_api_gateway_method_response" "data_post_500" {
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
  resource_id = aws_api_gateway_resource.generic_resource.id
  http_method = aws_api_gateway_method.generic_post.http_method
  status_code = "500"
  response_parameters = {
    "method.response.header.Content-Type" = true
  }
  response_models = {
    "application/json" = "UnifiedResponseModel"
  }
}
resource "aws_api_gateway_integration_response" "data_post_200_response" {
  depends_on        = [aws_api_gateway_integration.ddb_integration]
  rest_api_id       = aws_api_gateway_rest_api.generic_api.id
  resource_id       = aws_api_gateway_resource.generic_resource.id
  http_method       = aws_api_gateway_method.generic_post.http_method
  status_code       = "200"
  selection_pattern = "2\\d{2}"
  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }
  response_templates = {
    "application/json" = jsonencode({
      statusCode = 200,
      message    = "Data successfully posted."
    })
  }
}
resource "aws_api_gateway_integration_response" "data_post_4XX_response" {
  depends_on        = [aws_api_gateway_integration.ddb_integration]
  rest_api_id       = aws_api_gateway_rest_api.generic_api.id
  resource_id       = aws_api_gateway_resource.generic_resource.id
  http_method       = aws_api_gateway_method.generic_post.http_method
  status_code       = "400"
  selection_pattern = "4\\d{2}"
  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }
  response_templates = {
    "application/json" = jsonencode({
      "timestamp" : "$context.requestTime",
      "request" : {
        "body" : "$util.escapeJavaScript($input.json('$'))",
        "parameters" : "$util.escapeJavaScript($input.params())",
      },
      "response" : {
        "status" : "$context.status",
        "error_message_input" : "$input.path('$.errorMessage')",
        "status_code_input" : "$input.path('$.statusCode')",
        "error_message_context" : "$context.error.message"
      },
      }
    )
  }
}
resource "aws_api_gateway_integration_response" "data_post_5XX_response" {
  depends_on        = [aws_api_gateway_integration.ddb_integration]
  rest_api_id       = aws_api_gateway_rest_api.generic_api.id
  resource_id       = aws_api_gateway_resource.generic_resource.id
  http_method       = aws_api_gateway_method.generic_post.http_method
  status_code       = "500"
  selection_pattern = "5//d{2}"
  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }
  response_templates = {
    "application/json" = jsonencode({
      "timestamp" : "$context.requestTime",
      "request" : {
        "body" : "$util.escapeJavaScript($input.json('$'))",
        "parameters" : "$util.escapeJavaScript($input.params())",
      },
      "response" : {
        "status" : "$context.status",
        "error_message_input" : "$input.path('$.errorMessage')",
        "status_code_input" : "$input.path('$.statusCode')",
        "error_message_context" : "$context.error.message"
      },
      }
    )
  }
}

resource "aws_api_gateway_gateway_response" "default_4xx_response" {
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  status_code   = "400"
  response_type = "DEFAULT_4XX"
  response_templates = {
    "application/json" = jsonencode({
      "timestamp" : "$context.requestTime",
      "request" : {
        "body" : "$util.escapeJavaScript($input.json('$'))",
        "parameters" : "$util.escapeJavaScript($input.params())",
      },
      "response" : {
        "status" : "$context.status",
        "error_message_input" : "$input.path('$.errorMessage')",
        "status_code_input" : "$input.path('$.statusCode')",
        "error_message_context" : "$context.error.message"
      },
      }
    )
  }
}
resource "aws_api_gateway_gateway_response" "default_403_response" {
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  status_code   = "403"
  response_type = "ACCESS_DENIED"
  response_templates = {
    "application/json" = jsonencode({
      "timestamp" : "$context.requestTime",
      "request" : {
        "body" : "$util.escapeJavaScript($input.json('$'))",
        "parameters" : "$util.escapeJavaScript($input.params())",
      },
      "response" : {
        "status" : "$context.status",
        "error_message_input" : "$input.path('$.errorMessage')",
        "status_code_input" : "$input.path('$.statusCode')",
        "error_message_context" : "$context.error.message"
      },
      }
    )
  }
}
resource "aws_api_gateway_gateway_response" "default_404_response" {
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  status_code   = "404"
  response_type = "RESOURCE_NOT_FOUND"

  response_templates = {
    "application/json" = jsonencode({
      "timestamp" : "$context.requestTime",
      "request" : {
        "body" : "$util.escapeJavaScript($input.json('$'))",
        "parameters" : "$util.escapeJavaScript($input.params())",
      },
      "response" : {
        "status" : "$context.status",
        "error_message_input" : "$input.path('$.errorMessage')",
        "status_code_input" : "$input.path('$.statusCode')",
        "error_message_context" : "$context.error.message"
      },
      }
    )
  }
}
resource "aws_api_gateway_gateway_response" "default_5xx_response" {
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  status_code   = "500"
  response_type = "DEFAULT_5XX"
  response_templates = {
    "application/json" = jsonencode({
      "timestamp" : "$context.requestTime",
      "request" : {
        "body" : "$util.escapeJavaScript($input.json('$'))",
        "parameters" : "$util.escapeJavaScript($input.params())",
      },
      "response" : {
        "status" : "$context.status",
        "error_message_input" : "$input.path('$.errorMessage')",
        "status_code_input" : "$input.path('$.statusCode')",
        "error_message_context" : "$context.error.message"
      },
      }
    )
  }
}
