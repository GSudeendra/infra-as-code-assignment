variable "lambda_function_names" {
  description = "List of Lambda function names to monitor"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "lambda_duration_threshold" {
  description = "Threshold in milliseconds for Lambda duration alarm"
  type        = number
  default     = 5000
}

variable "create_api_gateway_alarms" {
  description = "Whether to create API Gateway alarms"
  type        = bool
  default     = true
}

variable "api_gateway_name" {
  description = "Name of the API Gateway to monitor"
  type        = string
  default     = ""
}

variable "alarm_actions" {
  description = "List of ARNs for alarm actions (e.g., SNS topics)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 