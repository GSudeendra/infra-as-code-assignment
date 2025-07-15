terraform {
  backend "s3" {
    bucket         = "iac-remote-state-160071257600-dev"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "iac-terraform-locks-dev"
    encrypt        = true
  }
}
