resource "aws_api_gateway_deployment" "deploy_api" {
  depends_on = [
    aws_api_gateway_rest_api.generic_api,
    aws_api_gateway_integration.ddb_integration,
    aws_api_gateway_integration.ddb_get,
  ]
  rest_api_id = aws_api_gateway_rest_api.generic_api.id
}

resource "aws_api_gateway_domain_name" "api_custom_domain" {
  domain_name              = "api.hamer.cloud"
  regional_certificate_arn = "arn:aws:acm:us-east-1:${data.aws_caller_identity.current.account_id}:certificate/7bba1b38-d28c-4665-aa2d-456785dc1b76"
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "api_base_path_mapping" {
  depends_on  = [aws_api_gateway_deployment.deploy_api]
  api_id      = aws_api_gateway_rest_api.generic_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  domain_name = aws_api_gateway_domain_name.api_custom_domain.domain_name
}

resource "aws_api_gateway_account" "apigw_account" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch_logging_role.arn
}

resource "aws_api_gateway_stage" "api_stage" {
  depends_on    = [aws_cloudwatch_log_group.apigw_log_group]
  deployment_id = aws_api_gateway_deployment.deploy_api.id
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  stage_name    = "prod"
  lifecycle { create_before_destroy = true }

  # Enable logs
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_log_group.arn
    format          = "{\"apiId\":\"$context.apiId\",\"domain\":{\"name\":\"$context.domainName\",\"prefix\":\"$context.domainPrefix\"},\"error\":{\"message\":\"$context.error.message\",\"messageString\":\"$context.error.messageString\",\"responseType\":\"$context.error.responseType\"},\"extendedRequestId\":\"$context.extendedRequestId\",\"httpMethod\":\"$context.httpMethod\",\"identity\":{\"accessKey\":\"$context.identity.accessKey\",\"accountId\":\"$context.identity.accountId\",\"apiKey\":\"$context.identity.apiKey\",\"apiKeyId\":\"$context.identity.apiKeyId\",\"caller\":\"$context.identity.caller\",\"principalOrgId\":\"$context.identity.principalOrgId\",\"sourceIp\":\"$context.identity.sourceIp\",\"user\":\"$context.identity.user\",\"userAgent\":\"$context.identity.userAgent\",\"userArn\":\"$context.identity.userArn\"},\"integration\":{\"error\":\"$context.integrationError\",\"integrationStatus\":\"$context.integration.integrationStatus\",\"latency\":\"$context.integration.latency\",\"requestId\":\"$context.integration.requestId\",\"status\":\"$context.integration.status\",\"errorMessage\":\"$context.integrationErrorMessage\"},\"integrationStatus\":\"$context.integrationStatus\",\"protocol\":\"$context.protocol\",\"requestId\":\"$context.requestId\",\"requestOverride\":{\"header\":\"$context.requestOverride.header.header_name\",\"querystring\":\"$context.requestOverride.querystring.param_name\",\"path\":\"$context.requestOverride.path.param_name\",\"body\":\"$context.requestOverride.body\"},\"requestTime\":\"$context.requestTime\",\"resource\":{\"id\":\"$context.resourceId\",\"path\":\"$context.resourcePath\"},\"response\":{\"length\":\"$context.responseLength\",\"override\":{\"header\":\"$context.responseOverride.header.header_name\",\"body\":\"$context.responseOverride.body\",\"status\":\"$context.responseOverride.status\"},\"status\":\"$context.responseStatus\",\"latency\":\"$context.responseLatency\"}}"
  }
  xray_tracing_enabled = true
}
