resource "aws_apigatewayv2_api" "secop" {
  name          = "${var.project}-${var.env}-api"
  protocol_type = "HTTP"
  description   = "API pública de SECOP II para recepción de procesos de contratación"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Api-Key"]
    max_age       = 300
  }

  tags = {
    Name        = "${var.project}-${var.env}-api"
    Environment = var.env
    Project     = var.project
  }
}

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.project}-${var.env}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project}-${var.env}-api-logs"
    Environment = var.env
    Project     = var.project
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.secop.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      latency        = "$context.integrationLatency"
      userAgent      = "$context.identity.userAgent"
    })
  }

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }

  tags = {
    Name        = "${var.project}-${var.env}-api-stage"
    Environment = var.env
    Project     = var.project
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.secop.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "contratos_post" {
  api_id    = aws_apigatewayv2_api.secop.id
  route_key = "POST /contratos"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "contratos_get" {
  api_id    = aws_apigatewayv2_api.secop.id
  route_key = "GET /contratos/{proceso_id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  authorization_type = "NONE"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.secop.execution_arn}/*/*"
}

output "api_url" {
  description = "URL base de la API Gateway de SECOP II"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_id" {
  description = "ID de la API Gateway"
  value       = aws_apigatewayv2_api.secop.id
}