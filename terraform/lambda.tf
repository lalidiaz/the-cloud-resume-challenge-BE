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