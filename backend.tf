terraform {
  required_version = ">= 1.0"
  backend "s3" {
    bucket         = "terraform-state-dev-14807638"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-dev-14807638"
    encrypt        = true
  }
} 