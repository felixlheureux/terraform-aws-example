terraform {
  backend "s3" {
    bucket = ""
    key    = "environments/global/vendor.tf"
    region = "us-east-1"
  }
}

module "vendor" {
  source      = "../../../modules/vendor"
  aws_region  = "us-east-1"
}