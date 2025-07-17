output "api_name" {
  description = "Name of the API Gateway"
  value       = aws_apigatewayv2_api.main.name
}

output "api_gateway_url" {
  description = "Invoke URL of the API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_id" {
  description = "ID of the API Gateway"
  value       = aws_apigatewayv2_api.main.id
} 