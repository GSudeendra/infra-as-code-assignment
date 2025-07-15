variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "project_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "iac"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "terraform-state-infra"
    Environment = "dev"
    Terraform   = "true"
  }
} 