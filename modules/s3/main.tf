resource "aws_s3_bucket" "static_content" {
  bucket = "static-content-${var.environment}-${var.random_suffix}"
}

resource "aws_s3_bucket_public_access_block" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "static_content" {
  bucket = aws_s3_bucket.static_content.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.static_content.id
  key    = "index.html"
  source = var.index_html_path
  etag   = filemd5(var.index_html_path)
}

resource "aws_s3_object" "error_html" {
  bucket = aws_s3_bucket.static_content.id
  key    = "error.html"
  source = var.error_html_path
  etag   = filemd5(var.error_html_path)
} 