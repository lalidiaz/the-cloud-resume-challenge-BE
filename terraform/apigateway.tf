# ----------------------------- API Gateway -----------------------------

resource "aws_apigatewayv2_api" "resume_api" {
  name          = "resume-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://${var.domain_name}"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age       = 300
  }

  tags = {
    Name = "TheCloudResumeChallenge"
  }
}


resource "aws_apigatewayv2_domain_name" "api_domain" {
  domain_name = "api.${var.domain_name}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [aws_acm_certificate_validation.cert_validation]

  tags = {
    Name = "TheCloudResumeChallenge"
  }
}

resource "aws_apigatewayv2_api_mapping" "resume_api_mapping" {
  api_id      = aws_apigatewayv2_api.resume_api.id
  domain_name = aws_apigatewayv2_domain_name.api_domain.id
  stage       = aws_apigatewayv2_stage.api_stage.id
}


resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.resume_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_log_group.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }


  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 30
    throttling_rate_limit    = 15
  }


  depends_on = [aws_cloudwatch_log_group.apigw_log_group]
}

resource "aws_apigatewayv2_route" "get_counter" {
  api_id    = aws_apigatewayv2_api.resume_api.id
  route_key = "GET /counter"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "post_counter" {
  api_id    = aws_apigatewayv2_api.resume_api.id
  route_key = "POST /counter"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}


resource "aws_api_gateway_account" "api_gw_settings" {
  cloudwatch_role_arn = aws_iam_role.api_gw_cloudwatch_role.arn
}