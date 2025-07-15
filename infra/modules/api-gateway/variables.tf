variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "lambda_functions" {
  description = "Map of Lambda function integration configs"
  type = map(object({
    function_name = string
    invoke_arn   = string
    route_key    = string
  }))
} 