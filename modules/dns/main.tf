data "cloudflare_zones" "domain" {
  filter {
    name = var.domain_name
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.domain_name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_record" "acm" {
  zone_id = data.cloudflare_zones.domain.zones[0].id

  name  = aws_acm_certificate.cert.domain_validation_options.*.resource_record_name[0]
  type  = aws_acm_certificate.cert.domain_validation_options.*.resource_record_type[0]
  value = trimsuffix(aws_acm_certificate.cert.domain_validation_options.*.resource_record_value[0], ".")

  // Must be set to false. ACM validation false otherwise
  proxied    = false
  depends_on = [aws_acm_certificate.cert]
}

resource "aws_acm_certificate_validation" "global" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = cloudflare_record.acm.*.hostname
}