terraform {
  backend "s3" {
    bucket         = "iac-user-management-state-dev"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "iac-user-management-lock-table-dev"
    encrypt        = true
  }
}
