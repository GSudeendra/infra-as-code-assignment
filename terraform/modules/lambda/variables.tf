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

variable "source_file" {
  description = "Path to the Lambda source file."
  type        = string
} 