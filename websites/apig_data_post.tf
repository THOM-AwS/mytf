resource "aws_api_gateway_integration" "ddb_integration" {
  depends_on              = [aws_api_gateway_method.generic_post]
  rest_api_id             = aws_api_gateway_rest_api.generic_api.id
  resource_id             = aws_api_gateway_resource.generic_resource.id
  http_method             = aws_api_gateway_method.generic_post.http_method
  passthrough_behavior    = "NEVER"
  content_handling        = "CONVERT_TO_TEXT"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${local.workspace.aws_region}:dynamodb:action/PutItem"
  credentials             = aws_iam_role.api_gw_to_ddb.arn
  type                    = "AWS"

  request_templates = {
    "application/json" = <<-EOF
    {
      "TableName": "${aws_dynamodb_table.generic_data.name}",
      "Item": {
        "lon": {
          "S": "$input.json('$.lon')"
        },
        "lat": {
          "S": "$input.json('$.lat')"
        },
        "timestamp": {
          "S": "$input.json('$.timestamp')"
        }
      }
    }
    EOF

    "application/x-www-form-urlencoded" = <<-EOF
#set($params = $input.path('$').split("&"))
{
  "TableName": "${aws_dynamodb_table.generic_data.name}",
  "Item": {
    "lon": {
      "S": "$!params[0].split('=')[1]"
    },
    "lat": {
      "S": "$!params[1].split('=')[1]"
    },
    "timestamp": {
      "S": "$!params[2].split('=')[1]"
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
    "method.request.header.Content-Type" = true
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
        "stage" : "$context.stage",
        "request_id" : "$context.requestId",
        "api_id" : "$context.apiId",
        "resource_path" : "$context.resourcePath",
        "http_method" : "$context.httpMethod",
        "source_ip" : "$context.identity.sourceIp",
        "user-agent" : "$context.identity.userAgent",
        "account_id" : "$context.identity.accountId",
        "caller" : "$context.identity.caller",
        "user" : "$context.identity.user",
        "api_key" : "$context.identity.apiKey",
        "user_arn" : "$context.identity.userArn",
        "body" : "$util.escapeJavaScript($input.json('$'))",
        "parameters" : "$util.escapeJavaScript($input.params())",
        "stage_variables" : {
          "example_variable" : "$stageVariables.example_variable"
        }
      },
      "response" : {
        "status" : "$context.status",
        "response_length" : "$context.responseLength",
        "response_latency" : "$context.responseLatency",
        "error_message_input" : "$input.path('$.errorMessage')",
        "status_code_input" : "$input.path('$.statusCode')",
        "error_message_context" : "$context.error.message"
      },
      "errors" : {
        "authorizer" : {
          "error" : "$context.authorizer.error",
          "status" : "$context.authorizer.status"
        },
        "authentication" : {
          "error" : "$context.authenticate.error",
          "status" : "$context.authenticate.status"
        },
        "integration" : {
          "error" : "$context.integration.error",
          "status" : "$context.integration.status"
        }
      },
      "metrics" : {
        "authorization_latency" : "$context.authorize.latency",
        "authorizer_latency" : "$context.authorizer.latency",
        "authentication_latency" : "$context.authenticate.latency",
        "integration_latency" : "$context.integration.latency"
      },
      "trace" : {
        "xray_trace_id" : "$context.xrayTraceId"
      }
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
        "stage" : "$context.stage",
        "request_id" : "$context.requestId",
        "api_id" : "$context.apiId",
        "resource_path" : "$context.resourcePath",
        "http_method" : "$context.httpMethod",
        "source_ip" : "$context.identity.sourceIp",
        "user-agent" : "$context.identity.userAgent",
        "account_id" : "$context.identity.accountId",
        "caller" : "$context.identity.caller",
        "user" : "$context.identity.user",
        "api_key" : "$context.identity.apiKey",
        "user_arn" : "$context.identity.userArn",
        "body" : "$util.escapeJavaScript($input.json('$'))",
        "parameters" : "$util.escapeJavaScript($input.params())",
        "stage_variables" : {
          "example_variable" : "$stageVariables.example_variable"
        }
      },
      "response" : {
        "status" : "$context.status",
        "response_length" : "$context.responseLength",
        "response_latency" : "$context.responseLatency",
        "error_message_input" : "$input.path('$.errorMessage')",
        "status_code_input" : "$input.path('$.statusCode')",
        "error_message_context" : "$context.error.message"
      },
      "errors" : {
        "authorizer" : {
          "error" : "$context.authorizer.error",
          "status" : "$context.authorizer.status"
        },
        "authentication" : {
          "error" : "$context.authenticate.error",
          "status" : "$context.authenticate.status"
        },
        "integration" : {
          "error" : "$context.integration.error",
          "status" : "$context.integration.status"
        }
      },
      "metrics" : {
        "authorization_latency" : "$context.authorize.latency",
        "authorizer_latency" : "$context.authorizer.latency",
        "authentication_latency" : "$context.authenticate.latency",
        "integration_latency" : "$context.integration.latency"
      },
      "trace" : {
        "xray_trace_id" : "$context.xrayTraceId"
      }
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
        "stage" : "$context.stage",
        "request_id" : "$context.requestId",
        "api_id" : "$context.apiId",
        "resource_path" : "$context.resourcePath",
        "http_method" : "$context.httpMethod",
        "source_ip" : "$context.identity.sourceIp",
        "user-agent" : "$context.identity.userAgent",
        "account_id" : "$context.identity.accountId",
        "caller" : "$context.identity.caller",
        "user" : "$context.identity.user",
        "api_key" : "$context.identity.apiKey",
        "user_arn" : "$context.identity.userArn",
        "body" : "$util.escapeJavaScript($input.json('$'))",
        "parameters" : "$util.escapeJavaScript($input.params())",
        "stage_variables" : {
          "example_variable" : "$stageVariables.example_variable"
        }
      },
      "response" : {
        "status" : "$context.status",
        "response_length" : "$context.responseLength",
        "response_latency" : "$context.responseLatency",
        "error_message_input" : "$input.path('$.errorMessage')",
        "status_code_input" : "$input.path('$.statusCode')",
        "error_message_context" : "$context.error.message"
      },
      "errors" : {
        "authorizer" : {
          "error" : "$context.authorizer.error",
          "status" : "$context.authorizer.status"
        },
        "authentication" : {
          "error" : "$context.authenticate.error",
          "status" : "$context.authenticate.status"
        },
        "integration" : {
          "error" : "$context.integration.error",
          "status" : "$context.integration.status"
        }
      },
      "metrics" : {
        "authorization_latency" : "$context.authorize.latency",
        "authorizer_latency" : "$context.authorizer.latency",
        "authentication_latency" : "$context.authenticate.latency",
        "integration_latency" : "$context.integration.latency"
      },
      "trace" : {
        "xray_trace_id" : "$context.xrayTraceId"
      }
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
        "stage" : "$context.stage",
        "request_id" : "$context.requestId",
        "api_id" : "$context.apiId",
        "resource_path" : "$context.resourcePath",
        "http_method" : "$context.httpMethod",
        "source_ip" : "$context.identity.sourceIp",
        "user-agent" : "$context.identity.userAgent",
        "account_id" : "$context.identity.accountId",
        "caller" : "$context.identity.caller",
        "user" : "$context.identity.user",
        "api_key" : "$context.identity.apiKey",
        "user_arn" : "$context.identity.userArn",
        "body" : "$util.escapeJavaScript($input.json('$'))",
        "parameters" : "$util.escapeJavaScript($input.params())",
        "stage_variables" : {
          "example_variable" : "$stageVariables.example_variable"
        }
      },
      "response" : {
        "status" : "$context.status",
        "response_length" : "$context.responseLength",
        "response_latency" : "$context.responseLatency",
        "error_message_input" : "$input.path('$.errorMessage')",
        "status_code_input" : "$input.path('$.statusCode')",
        "error_message_context" : "$context.error.message"
      },
      "errors" : {
        "authorizer" : {
          "error" : "$context.authorizer.error",
          "status" : "$context.authorizer.status"
        },
        "authentication" : {
          "error" : "$context.authenticate.error",
          "status" : "$context.authenticate.status"
        },
        "integration" : {
          "error" : "$context.integration.error",
          "status" : "$context.integration.status"
        }
      },
      "metrics" : {
        "authorization_latency" : "$context.authorize.latency",
        "authorizer_latency" : "$context.authorizer.latency",
        "authentication_latency" : "$context.authenticate.latency",
        "integration_latency" : "$context.integration.latency"
      },
      "trace" : {
        "xray_trace_id" : "$context.xrayTraceId"
      }
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
        "stage" : "$context.stage",
        "request_id" : "$context.requestId",
        "api_id" : "$context.apiId",
        "resource_path" : "$context.resourcePath",
        "http_method" : "$context.httpMethod",
        "source_ip" : "$context.identity.sourceIp",
        "user-agent" : "$context.identity.userAgent",
        "account_id" : "$context.identity.accountId",
        "caller" : "$context.identity.caller",
        "user" : "$context.identity.user",
        "api_key" : "$context.identity.apiKey",
        "user_arn" : "$context.identity.userArn",
        "body" : "$util.escapeJavaScript($input.json('$'))",
        "parameters" : "$util.escapeJavaScript($input.params())",
        "stage_variables" : {
          "example_variable" : "$stageVariables.example_variable"
        }
      },
      "response" : {
        "status" : "$context.status",
        "response_length" : "$context.responseLength",
        "response_latency" : "$context.responseLatency",
        "error_message_input" : "$input.path('$.errorMessage')",
        "status_code_input" : "$input.path('$.statusCode')",
        "error_message_context" : "$context.error.message"
      },
      "errors" : {
        "authorizer" : {
          "error" : "$context.authorizer.error",
          "status" : "$context.authorizer.status"
        },
        "authentication" : {
          "error" : "$context.authenticate.error",
          "status" : "$context.authenticate.status"
        },
        "integration" : {
          "error" : "$context.integration.error",
          "status" : "$context.integration.status"
        }
      },
      "metrics" : {
        "authorization_latency" : "$context.authorize.latency",
        "authorizer_latency" : "$context.authorizer.latency",
        "authentication_latency" : "$context.authenticate.latency",
        "integration_latency" : "$context.integration.latency"
      },
      "trace" : {
        "xray_trace_id" : "$context.xrayTraceId"
      }
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
        "stage" : "$context.stage",
        "request_id" : "$context.requestId",
        "api_id" : "$context.apiId",
        "resource_path" : "$context.resourcePath",
        "http_method" : "$context.httpMethod",
        "source_ip" : "$context.identity.sourceIp",
        "user-agent" : "$context.identity.userAgent",
        "account_id" : "$context.identity.accountId",
        "caller" : "$context.identity.caller",
        "user" : "$context.identity.user",
        "api_key" : "$context.identity.apiKey",
        "user_arn" : "$context.identity.userArn",
        "body" : "$util.escapeJavaScript($input.json('$'))",
        "parameters" : "$util.escapeJavaScript($input.params())",
        "stage_variables" : {
          "example_variable" : "$stageVariables.example_variable"
        }
      },
      "response" : {
        "status" : "$context.status",
        "response_length" : "$context.responseLength",
        "response_latency" : "$context.responseLatency",
        "error_message_input" : "$input.path('$.errorMessage')",
        "status_code_input" : "$input.path('$.statusCode')",
        "error_message_context" : "$context.error.message"
      },
      "errors" : {
        "authorizer" : {
          "error" : "$context.authorizer.error",
          "status" : "$context.authorizer.status"
        },
        "authentication" : {
          "error" : "$context.authenticate.error",
          "status" : "$context.authenticate.status"
        },
        "integration" : {
          "error" : "$context.integration.error",
          "status" : "$context.integration.status"
        }
      },
      "metrics" : {
        "authorization_latency" : "$context.authorize.latency",
        "authorizer_latency" : "$context.authorizer.latency",
        "authentication_latency" : "$context.authenticate.latency",
        "integration_latency" : "$context.integration.latency"
      },
      "trace" : {
        "xray_trace_id" : "$context.xrayTraceId"
      }
      }
    )
  }
}
