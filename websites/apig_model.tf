resource "aws_api_gateway_model" "UnifiedResponseModel" {
  rest_api_id  = aws_api_gateway_rest_api.generic_api.id
  name         = "UnifiedResponseModel"
  content_type = "application/json"
  schema = jsonencode({
    title = "UnifiedResponseModel",
    type  = "object",
    properties = {
      status = {
        type        = "string",
        enum        = ["Success", "Error"],
        description = "Indicates whether the response denotes success or an error."
      },
      code = {
        type        = "integer",
        description = "HTTP status code. E.g., 200 for success, 400 for client errors, and 500 for server errors."
      },
      message = {
        type        = "string",
        description = "A descriptive message explaining the status or error."
      },
      details = {
        type = "array",
        items = {
          type = "object",
          properties = {
            field = { type = "string", description = "Field related to the error, if applicable." },
            error = { type = "string", description = "Specific error detail for the field." }
          }
        },
        description = "More detailed information on errors, especially for multifaceted errors."
      },
      data = {
        type        = "object",
        description = "Holds actual response data for successful responses."
      },
      timestamp = {
        type        = "string",
        format      = "date-time",
        description = "Timestamp indicating when the response was generated."
      }
    },
    required = ["status", "code", "message", "timestamp"]
  })
}
