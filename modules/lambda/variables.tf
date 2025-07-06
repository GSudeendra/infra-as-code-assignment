variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "handler" {
  description = "Handler for the Lambda function."
  type        = string
}

variable "runtime" {
  description = "Runtime for the Lambda function."
  type        = string
}

variable "zip_path" {
  description = "Path to the Lambda ZIP file."
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name for tagging and conditions"
  type        = string
  default     = "dev"
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for restricted permissions"
  type        = string
  default     = "*"
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for restricted permissions"
  type        = string
  default     = "*"
}

variable "reserved_concurrent_executions" {
  description = "Number of reserved concurrent executions for the Lambda function"
  type        = number
  default     = -1
}

variable "vpc_config" {
  description = "VPC configuration for Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "dead_letter_queue_arn" {
  description = "ARN of the Dead Letter Queue for failed executions"
  type        = string
  default     = null
} 