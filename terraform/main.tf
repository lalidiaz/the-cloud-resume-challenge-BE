# ----------------------------- S3 -----------------------------

resource "aws_s3_bucket" "cloud_resume_challenge_laura_diaz" {
  bucket        = "cloud-resume-challenge-laura-diaz"
  force_destroy = true
  tags = {
    Name = "TheCloudResumeChallenge"
  }
}

resource "aws_s3_bucket_cors_configuration" "cloud_resume_challenge_laura_diaz_cors" {
  bucket = aws_s3_bucket.cloud_resume_challenge_laura_diaz.id

  cors_rule {
    allowed_origins = [var.domain_name]
    allowed_methods = ["GET", "PUT"]
    allowed_headers = ["Content-Type"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_versioning" "cloud_resume_laura_diaz_versioning" {
  bucket = aws_s3_bucket.cloud_resume_challenge_laura_diaz.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.cloud_resume_challenge_laura_diaz.id

  rule {
    id = "cleanup-old-versions"

    filter {
      tag {
        key   = "Name"
        value = "TheCloudResumeChallenge"
      }
    }
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}


resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.cloud_resume_challenge_laura_diaz.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_block_public_access" {
  bucket = aws_s3_bucket.cloud_resume_challenge_laura_diaz.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.cloud_resume_challenge_laura_diaz.id
  policy = data.aws_iam_policy_document.cloudfront_s3_access.json
}


# ----------------------------- ACM -----------------------------

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  key_algorithm             = "RSA_2048"

  tags = {
    Name = "TheCloudResumeChallenge"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}


# ----------------------------- Route 53 -----------------------------

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.public_zone.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true



  lifecycle {
    ignore_changes = all
  }
}


resource "aws_route53_record" "website_record" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}



resource "aws_route53_record" "api_record" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"


  alias {
    name                   = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}


# ----------------------------- Cloudfront -----------------------------

resource "aws_cloudfront_origin_access_control" "cloudfront_origin_access" {
  name                              = "cloudfront_origin_access"
  description                       = "Manages an AWS CloudFront Origin Access Control, which is used by CloudFront Distributions with an Amazon S3 bucket as the origin."
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.cloud_resume_challenge_laura_diaz.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.cloud_resume_challenge_laura_diaz.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_origin_access.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods            = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${aws_s3_bucket.cloud_resume_challenge_laura_diaz.id}"
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = aws_cloudfront_cache_policy.website_cache.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers_policy.id

  }


  aliases = [var.domain_name]


  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }

  tags = {
    Name = "TheCloudResumeChallenge"
  }
}

resource "aws_cloudfront_response_headers_policy" "security_headers_policy" {
  name = "security-headers-policy"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["Content-Type"]
    }

    access_control_allow_methods {
      items = ["GET", "OPTIONS", "PUT"]
    }

    access_control_allow_origins {
      items = [var.domain_name]
    }

    origin_override = true
  }

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdnjs.cloudflare.com; font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; connect-src 'self' https://api.lauradiazcloudengineer.com; img-src 'self' data:;"
      override                = true
    }
  }
}


resource "aws_cloudfront_cache_policy" "website_cache" {
  name        = "resume-website-cache-policy"
  comment     = "Cache policy for my cloud resume challenge website"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}


# ----------------------------- DynamoDB -----------------------------

resource "aws_dynamodb_table_item" "initial_counter" {
  table_name = aws_dynamodb_table.count_table.name
  hash_key   = aws_dynamodb_table.count_table.hash_key

  item = <<ITEM
{
  "id": {"S": "visitors"},
  "counter": {"N": "0"}
 }
ITEM

}

resource "aws_dynamodb_table" "count_table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }


  tags = {
    Name = "TheCloudResumeChallenge"
  }
}

# ----------------------------- API Gateway -----------------------------

resource "aws_apigatewayv2_api" "resume_api" {
  name          = "resume-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://${var.domain_name}"]
    allow_methods = ["GET", "PUT", "OPTIONS"]
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

resource "aws_apigatewayv2_route" "put_counter" {
  api_id    = aws_apigatewayv2_api.resume_api.id
  route_key = "PUT /counter"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}


resource "aws_api_gateway_account" "api_gw_settings" {
  cloudwatch_role_arn = aws_iam_role.api_gw_cloudwatch_role.arn
}

# ----------------------------- LAMBDA -----------------------------

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.resume_api.id
  integration_type       = "AWS_PROXY" 
  integration_uri        = aws_lambda_function.counter.invoke_arn
  payload_format_version = "2.0"
  integration_method     = "POST" 
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.resume_api.execution_arn}/*/*"
}


resource "aws_lambda_function" "counter" {
  function_name    = "lambda_handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.9"
  s3_bucket     = "lambdafunctionlaura"
  s3_key        = "lambda_function.zip"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.count_table.name
    }
  }
}

# ----------------------------- IAM Policies -------------------------

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name   = "lambda-dynamodb-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_dynamodb_policy.json
}

resource "aws_iam_role_policy" "api_gw_cloudwatch_role_policy" {
  name   = "api-gateway-cloudwatch-policy"
  role   = aws_iam_role.api_gw_cloudwatch_role.id
  policy = data.aws_iam_policy_document.api_gw_cloudwatch_permissions.json
}


resource "aws_iam_role_policy" "lambda_logging" {
  name   = "lambda-logging-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "api_gw_cloudwatch_policy_attachment" {
  role       = aws_iam_role.api_gw_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}


# ----------------------------- IAM Roles -----------------------------

resource "aws_iam_role" "api_gw_cloudwatch_role" {
  name               = "api_gw_cloudwatch_role"
  assume_role_policy = data.aws_iam_policy_document.api_gw_cloudwatch_policy.json
}

resource "aws_iam_role" "lambda_role" {
  name               = "counter-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}


# ----------------------------- Cloudwatch -----------------------------

resource "aws_cloudwatch_log_group" "apigw_log_group" {
  name              = "cloud-resume-challenge-log-group"
  retention_in_days = 30

  tags = {
    Name = "TheCloudResumeChallenge"
  }
}


resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda-counter-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This alarm monitors lambda function errors"

  dimensions = {
    FunctionName = aws_lambda_function.counter.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_high_request_count" {
  alarm_name          = "api-gateway-high-request-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  period              = "60"
  statistic           = "Sum"
  threshold           = "30"
  alarm_description   = "This alarm triggers when the API receives too many requests in a short period, which might indicate bot activity"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = aws_apigatewayv2_api.resume_api.id
  }

  alarm_actions = [aws_sns_topic.api_alarms.arn]
  ok_actions    = [aws_sns_topic.api_alarms.arn]
}


resource "aws_cloudwatch_metric_alarm" "api_high_4xx_error_rate" {
  alarm_name          = "api-gateway-high-4xx-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "60"
  statistic           = "Sum"
  threshold           = "30"
  alarm_description   = "This alarm triggers when there are too many 4XX errors, which might indicate scanning/probing activity"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = aws_apigatewayv2_api.resume_api.id
  }

  alarm_actions = [aws_sns_topic.api_alarms.arn]
  ok_actions    = [aws_sns_topic.api_alarms.arn]
}



# ----------------------------- SNS -----------------------------

resource "aws_sns_topic" "api_alarms" {
  name = "api-gateway-cloud-resume-challenge-topic"
}

resource "aws_sns_topic_subscription" "api_alarms_email" {
  topic_arn = aws_sns_topic.api_alarms.arn
  protocol  = "email"
  endpoint  = var.email
}