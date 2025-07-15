terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Generate random suffix for resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# DynamoDB Module
module "dynamodb" {
  source = "./modules/dynamodb"

  environment   = var.environment
  random_suffix = random_id.suffix.hex
  tags          = var.tags
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  environment     = var.environment
  random_suffix   = random_id.suffix.hex
  index_html_path = "../html/index.html"
  error_html_path = "../html/error.html"
  tags            = var.tags
}

# Lambda Modules
module "register_user_lambda" {
  source = "./modules/lambda"

  function_name = "register_user"
  handler       = "register_user.lambda_handler"
  runtime       = "python3.9"
  zip_path      = "./modules/lambda/register_user.zip"
  environment   = var.environment
  environment_variables = {
    DYNAMODB_TABLE = module.dynamodb.dynamodb_table_name
  }
  dynamodb_table_arn             = module.dynamodb.dynamodb_table_arn
  s3_bucket_arn                  = module.s3.s3_bucket_arn
  reserved_concurrent_executions = 10
}

module "verify_user_lambda" {
  source = "./modules/lambda"

  function_name = "verify_user"
  handler       = "verify_user.lambda_handler"
  runtime       = "python3.9"
  zip_path      = "./modules/lambda/verify_user.zip"
  environment   = var.environment
  environment_variables = {
    DYNAMODB_TABLE = module.dynamodb.dynamodb_table_name
    S3_BUCKET      = module.s3.s3_bucket_name
  }
  dynamodb_table_arn             = module.dynamodb.dynamodb_table_arn
  s3_bucket_arn                  = module.s3.s3_bucket_arn
  reserved_concurrent_executions = 10
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api-gateway"

  api_name = "user-management-api"
  tags     = var.tags

  lambda_functions = {
    register_user = {
      function_name = module.register_user_lambda.function_name
      invoke_arn    = module.register_user_lambda.function_invoke_arn
      route_key     = "POST /register"
    }
    verify_user = {
      function_name = module.verify_user_lambda.function_name
      invoke_arn    = module.verify_user_lambda.function_invoke_arn
      route_key     = "GET /"
    }
  }
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  environment = var.environment
  lambda_function_names = [
    module.register_user_lambda.function_name,
    module.verify_user_lambda.function_name
  ]

  create_api_gateway_alarms = true
  api_gateway_name          = module.api_gateway.api_name
  log_retention_days        = 14
  lambda_duration_threshold = 5000
  alarm_actions             = [] # Add SNS topic ARNs here if needed

  tags = var.tags
}
