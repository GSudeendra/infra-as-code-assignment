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
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      # DynamoDB permissions
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ]
        Resource = "*"
      },
      # S3 permissions (only for verify_user)
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
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

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  handler       = var.handler
  runtime       = var.runtime
  role          = aws_iam_role.lambda_exec.arn
  filename      = var.zip_path
  source_code_hash = filebase64sha256(var.zip_path)
  environment {
    variables = var.environment_variables
  }
  timeout = 10
}

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