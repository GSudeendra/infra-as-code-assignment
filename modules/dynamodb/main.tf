terraform {
  required_version = ">= 1.0"
}

resource "aws_dynamodb_table" "users" {
  name         = "users-${var.environment}-${var.random_suffix}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  # Enable point-in-time recovery for backup
  point_in_time_recovery {
    enabled = true
  }

  # Enable server-side encryption with AWS managed key
  server_side_encryption {
    enabled = true
  }

  tags = var.tags
} 