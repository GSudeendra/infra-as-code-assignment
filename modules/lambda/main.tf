terraform {
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
  required_version = ">= 1.5.0"
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-exec-role-${random_id.suffix.hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.function_name}-policy-${random_id.suffix.hex}"
  description = "IAM policy for Lambda function ${var.function_name}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}:*"
      },
      # DynamoDB permissions - restricted to specific table
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ]
        Resource = var.dynamodb_table_arn
      },
      # S3 permissions - restricted to specific bucket and objects
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/Environment" = var.environment
          }
        }
      },
      # X-Ray permissions
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Add VPC execution role policy if VPC is enabled
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count = var.vpc_config != null ? 1 : 0

  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  handler          = var.handler
  runtime          = var.runtime
  role             = aws_iam_role.lambda_exec.arn
  filename         = var.zip_path
  source_code_hash = filebase64sha256(var.zip_path)

  environment {
    variables = var.environment_variables
  }

  timeout = 10

  # Enable X-Ray tracing
  tracing_config {
    mode = "Active"
  }

  # Configure concurrent execution limit
  reserved_concurrent_executions = var.reserved_concurrent_executions

  # VPC configuration (optional)
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Dead Letter Queue configuration (optional)
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_queue_arn != null ? [var.dead_letter_queue_arn] : []
    content {
      target_arn = dead_letter_config.value
    }
  }
}

# Data sources for current region and account
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Commented out to let AWS manage log groups automatically
# This prevents conflicts with automatically created log groups
# resource "aws_cloudwatch_log_group" "lambda_log" {
#   name              = "/aws/lambda/${var.function_name}-${random_id.suffix.hex}"
#   retention_in_days = 7
#   
#   lifecycle {
#     prevent_destroy = true
#     create_before_destroy = true
#     ignore_changes = [retention_in_days]
#   }
# }

resource "random_id" "suffix" {
  byte_length = 4
} 