# ----------------------------- SNS -----------------------------

resource "aws_sns_topic" "api_alarms" {
  name = "api-gateway-cloud-resume-challenge-topic"
}

resource "aws_sns_topic_subscription" "api_alarms_email" {
  topic_arn = aws_sns_topic.api_alarms.arn
  protocol  = "email"
  endpoint  = var.email
}