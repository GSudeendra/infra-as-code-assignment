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