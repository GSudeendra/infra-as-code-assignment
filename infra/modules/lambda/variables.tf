variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "Lambda handler (e.g., file.function)"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.9)"
  type        = string
}

variable "zip_path" {
  description = "Path to the Lambda deployment package (zip)"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  type        = string
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency for the Lambda function"
  type        = number
  default     = 10
}

variable "vpc_config" {
  description = "VPC configuration for the Lambda function (optional)"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "dead_letter_queue_arn" {
  description = "ARN of the Dead Letter Queue (optional)"
  type        = string
  default     = null
} 