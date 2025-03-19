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

