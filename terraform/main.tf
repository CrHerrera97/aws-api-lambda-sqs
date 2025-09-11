provider "aws" {
  region = "us-east-1"
}

# --- Cola SQS ---
resource "aws_sqs_queue" "pedidos" {
  name = "pedidos-queue"
}

# --- Role para Lambda ---
resource "aws_iam_role" "lambda_role" {
  name = "lambda-pedidos-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach policies
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

# --- Producer Lambda ---
resource "aws_lambda_function" "producer" {
  function_name = "producer-pedidos"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.handler"
  runtime       = "nodejs18.x"

  filename         = "${path.module}/../producer.zip"
  source_code_hash = filebase64sha256("${path.module}/../producer.zip")

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.pedidos.url
    }
  }
}

# --- API Gateway ---
resource "aws_apigatewayv2_api" "api" {
  name          = "PedidosAPI"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "producer_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.producer.arn}/invocations"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "pedidos_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /pedidos"
  target    = "integrations/${aws_apigatewayv2_integration.producer_integration.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "prod"
  auto_deploy = true
}

# --- Consumer Lambda ---
resource "aws_lambda_function" "consumer" {
  function_name = "consumer-pedidos"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.handler"
  runtime       = "nodejs18.x"

  filename         = "${path.module}/../consumer.zip"
  source_code_hash = filebase64sha256("${path.module}/../consumer.zip")
}

# --- Vincular SQS a Consumer ---
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.pedidos.arn
  function_name    = aws_lambda_function.consumer.arn
}
