variable "environment" {
  description = "Environment name"
  type        = string
}

variable "random_suffix" {
  description = "Random suffix for resource names"
  type        = string
}

variable "index_html_path" {
  description = "Path to the index.html file"
  type        = string
}

variable "error_html_path" {
  description = "Path to the error.html file"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 