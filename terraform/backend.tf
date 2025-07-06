terraform {
  backend "s3" {
    bucket         = "terraform-state-dev-87efb0a8"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-dev-87efb0a8"
    encrypt        = true
  }
}
