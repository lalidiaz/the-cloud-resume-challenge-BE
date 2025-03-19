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
