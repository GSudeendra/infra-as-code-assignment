resource "aws_dynamodb_table" "users" {
  name           = "users-${var.environment}-${var.random_suffix}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = var.tags
} 