# API Gateway Module - Main Configuration
# Creates HTTP API Gateway with Lambda integrations

# Create HTTP API
resource "aws_apigatewayv2_api" "main" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = "HTTP API for user management system"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }

  tags = var.tags
}

# Create default stage
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  tags = var.tags
}

# Create Lambda integrations for each function
resource "aws_apigatewayv2_integration" "lambda_integrations" {
  for_each = var.lambda_functions

  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  integration_uri    = each.value.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# Create routes for each Lambda function
resource "aws_apigatewayv2_route" "lambda_routes" {
  for_each = var.lambda_functions

  api_id    = aws_apigatewayv2_api.main.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integrations[each.key].id}"
}

# Create Lambda permissions for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  for_each = var.lambda_functions

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
} 