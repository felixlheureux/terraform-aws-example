output "website_endpoint" {
  description = "assets bucket endpoint"
  value       = aws_s3_bucket.assets.website_endpoint
}