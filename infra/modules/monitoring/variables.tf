variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "lambda_function_names" {
  description = "List of Lambda function names to monitor"
  type        = list(string)
}

variable "create_api_gateway_alarms" {
  description = "Whether to create API Gateway alarms"
  type        = bool
  default     = false
}

variable "api_gateway_name" {
  description = "Name of the API Gateway to monitor"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 365
}

variable "lambda_duration_threshold" {
  description = "Threshold for Lambda duration alarm (ms)"
  type        = number
  default     = 5000
}

variable "alarm_actions" {
  description = "List of ARNs to notify for alarms (e.g., SNS topics)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 