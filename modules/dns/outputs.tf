output "aws_certificate_arn" {
  description = "aws acm certificate arn"
  value       = aws_acm_certificate_validation.global.certificate_arn
}