output "aws_certificate_arn" {
  description = "aws acm certificate arn"
  value       = module.dns.aws_certificate_arn
}