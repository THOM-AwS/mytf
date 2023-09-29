resource "aws_api_gateway_deployment" "deploy_api" {
  depends_on = [
    aws_api_gateway_rest_api.generic_api,
    aws_api_gateway_integration.ddb_integration,
    aws_api_gateway_integration_response.ddb_200_response,
    aws_api_gateway_integration_response.root_mock_200_response
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
  depends_on    = [aws_cloudwatch_log_group.apigw_log_group, aws_api_gateway_deployment.deploy_api]
  deployment_id = aws_api_gateway_deployment.deploy_api.id
  rest_api_id   = aws_api_gateway_rest_api.generic_api.id
  stage_name    = "prod"

  # Enable logs
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_log_group.arn
    format          = "$context.requestId [$context.requestTime] - $context.identity.sourceIp \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength | PrincipalId: $context.identity.principalId | Caller: $context.identity.caller | User: $context.identity.user | UserAgent: $context.identity.userAgent | AccountId: $context.identity.accountId | ApiKey: $context.identity.apiKey | CognitoIdentityPoolId: $context.identity.cognitoIdentityPoolId | CognitoAuthenticationType: $context.identity.cognitoAuthenticationType | CognitoAuthenticationProvider: $context.identity.cognitoAuthenticationProvider | CognitoIdentityId: $context.identity.cognitoIdentityId | CognitoAuthenticationType: $context.identity.cognitoAuthenticationType | AuthorizerPrincipalId: $context.authorizer.principalId | Error Message: $context.error.message | MessageString: $context.error.messageString | ResponseType: $context.error.responseType | IntegrationError: $context.integration.error | IntegrationStatus: $context.integration.integrationStatus | Integration Latency: $context.integration.latency | Response Latency: $context.responseLatency | Integration Status: $context.integration.status | ErrorMessage: $context.integrationErrorMessage | IntegrationStatus: $context.integrationStatus"
  }
  xray_tracing_enabled = true
}
