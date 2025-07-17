terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.5.0"
}

resource "aws_s3_bucket" "static_content" {
  bucket = "static-content-${var.environment}-${var.random_suffix}"
  tags   = var.tags
}

# Create access logging bucket
resource "aws_s3_bucket" "access_logs" {
  bucket = "access-logs-${var.environment}-${var.random_suffix}"
  tags   = var.tags
}

# Configure access logging for the main bucket
resource "aws_s3_bucket_logging" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "log/"
}

# Configure public access block - enable all restrictions
resource "aws_s3_bucket_public_access_block" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# Configure public access block for access logs bucket
resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Server-side encryption for access logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Versioning configuration
resource "aws_s3_bucket_versioning" "static_content" {
  bucket = aws_s3_bucket.static_content.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Versioning for access logs bucket
resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle configuration for main bucket
resource "aws_s3_bucket_lifecycle_configuration" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Lifecycle configuration for access logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "cleanup_old_logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Event notifications for main bucket
resource "aws_s3_bucket_notification" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  # Example: Notify on object creation
  # This can be extended with Lambda, SQS, or SNS notifications
  depends_on = [aws_s3_bucket_public_access_block.static_content]
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static_content.id
  key          = "index.html"
  source       = var.index_html_path
  etag         = filemd5(var.index_html_path)
  content_type = "text/html"
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.static_content.id
  key          = "error.html"
  source       = var.error_html_path
  etag         = filemd5(var.error_html_path)
  content_type = "text/html"
}

resource "aws_s3_bucket_website_configuration" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "static_content_public_read" {
  bucket = aws_s3_bucket.static_content.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_content.arn}/*"
      }
    ]
  })
} 