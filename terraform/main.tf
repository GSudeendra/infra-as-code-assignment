terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "twbeach"
  default_tags {
    tags = var.tags
  }
}

module "hello_world_lambda" {
  source        = "./modules/lambda"
  function_name = "${var.environment}-hello-world-lambda"
  handler       = "hello_world.lambda_handler"
  runtime       = "python3.11"
  source_file   = "${path.root}/../src/hello_world.py"
}

module "apigateway" {
  source                      = "./modules/apigateway"
  lambda_function_arn         = module.hello_world_lambda.function_arn
  lambda_function_invoke_arn  = module.hello_world_lambda.function_arn
  lambda_function_name        = module.hello_world_lambda.function_name
}
