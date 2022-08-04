terraform {
  backend "s3" {
    bucket = ""
    key    = "environments/global/dns.tf"
    region = "us-east-1"
  }
}

variable "cloudflare_api_key" {}
variable "cloudflare_email" {}

module "dns" {
  source             = "../../../modules/dns"
  aws_region         = "us-east-1"
  domain_name        = ""
  cloudflare_api_key = "${var.cloudflare_api_key}"
  cloudflare_email   = "${var.cloudflare_email}"
}