output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = module.api_gateway.api_gateway_url
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb.dynamodb_table_arn
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.s3_bucket_arn
}

output "lambda_function_names" {
  description = "Names of the Lambda functions"
  value = {
    register_user = module.register_user_lambda.function_name
    verify_user   = module.verify_user_lambda.function_name
  }
}
