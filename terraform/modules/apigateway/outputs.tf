output "api_endpoint" {
  description = "The API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

