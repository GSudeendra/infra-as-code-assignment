output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = module.hello_world_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = module.hello_world_lambda.function_arn
}

output "api_gateway_url" {
  description = "URL of the deployed API Gateway endpoint"
  value       = module.apigateway.api_endpoint
}
