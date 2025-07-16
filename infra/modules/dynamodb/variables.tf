variable "environment" {
  description = "Deployment environment (e.g., dev, dev)"
  type        = string
}

variable "random_suffix" {
  description = "Random suffix for resource uniqueness"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 