output "s3_bucket_arn" {
  description = "ARN of the static content S3 bucket"
  value       = aws_s3_bucket.static_content.arn
}

output "s3_bucket_name" {
  description = "Name of the static content S3 bucket"
  value       = aws_s3_bucket.static_content.id
} 