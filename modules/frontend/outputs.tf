output "website_endpoint" {
  description = "frontend bucket endpoint"
  value       = aws_s3_bucket.frontend.website_endpoint
}