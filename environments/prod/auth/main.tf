terraform {
  backend "s3" {
    bucket = ""
    # The key definition changes following the environment
    key    = "environments/prod/auth.tf"
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

module "auth" {
  source              = "../../../modules/auth"
  aws_region          = "us-east-1"
  project             = ""
  environment         = "prod"
  domain_name         = ""
  subdomain_name      = ""
  aws_certificate_arn = data.terraform_remote_state.dns.outputs.aws_certificate_arn
  cloudflare_api_key  = "${var.cloudflare_api_key}"
  cloudflare_email    = "${var.cloudflare_email}"
}