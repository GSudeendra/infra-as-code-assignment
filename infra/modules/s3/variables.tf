variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "random_suffix" {
  description = "Random suffix for bucket uniqueness"
  type        = string
}

variable "index_html_path" {
  description = "Path to index.html file to upload"
  type        = string
}

variable "error_html_path" {
  description = "Path to error.html file to upload"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 