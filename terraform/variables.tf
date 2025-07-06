variable "aws_region" {
  description = "AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Default tags to apply to resources."
  type        = map(string)
  default = {
    Project = "iac-assignment"
    Owner   = "student"
  }
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)."
  type        = string
  default     = "dev"
} 