# API Gateway Module - Variables
# Defines input variables for the API Gateway module

variable "api_name" {
  description = "Name of the HTTP API Gateway"
  type        = string
}

variable "lambda_functions" {
  description = "Map of Lambda functions to integrate with API Gateway"
  type = map(object({
    function_name = string
    invoke_arn    = string
    route_key     = string
  }))
}

variable "tags" {
  description = "Tags to apply to API Gateway resources"
  type        = map(string)
  default     = {}
} 