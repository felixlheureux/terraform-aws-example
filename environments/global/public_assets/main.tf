terraform {
  backend "s3" {
    bucket = ""
    # The key definition changes following the environment
    key    = "environments/global/public-assets.tf"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "dns" {
  backend = "s3"

  config = {
    bucket = ""
    key    = "environments/global/dns.tf"
    region = "us-east-1"
  }
}

variable "cloudflare_api_key" {}
variable "cloudflare_email" {}

module "public_assets" {
  source              = "../../../modules/public_assets"
  aws_region          = "us-east-1"
  project             = ""
  domain_name         = ""
  subdomain_name      = "cdn"
  aws_certificate_arn = data.terraform_remote_state.dns.outputs.aws_certificate_arn
  cloudflare_api_key  = "${var.cloudflare_api_key}"
  cloudflare_email    = "${var.cloudflare_email}"
}