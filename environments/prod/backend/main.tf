terraform {
  backend "s3" {
    bucket = ""
    # The key definition changes following the environment
    key    = "environments/prod/backend.tf"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = ""
    key    = "environments/prod/network.tf"
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

data "terraform_remote_state" "vendor" {
  backend = "s3"

  config = {
    bucket = ""
    key    = "environments/global/vendor.tf"
    region = "us-east-1"
  }
}

variable "cloudflare_api_key" {}
variable "cloudflare_email" {}
variable "artifact_version" {}

module "backend" {
  source                 = "../../../modules/backend"
  aws_region             = "us-east-1"
  project                = ""
  environment            = "prod"
  domain_name            = ""
  subdomain_name_backend = "api"
  vpc                    = data.terraform_remote_state.network.outputs.vpc
  aws_certificate_arn    = data.terraform_remote_state.dns.outputs.aws_certificate_arn
  artifacts_bucket       = data.terraform_remote_state.vendor.outputs.artifacts_bucket
  cloudflare_api_key     = "${var.cloudflare_api_key}"
  cloudflare_email       = "${var.cloudflare_email}"
  artifact_version       = "${var.artifact_version}"
}