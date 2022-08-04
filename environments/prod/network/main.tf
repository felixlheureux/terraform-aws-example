terraform {
  backend "s3" {
    bucket = ""
    # The key definition changes following the environment
    key    = "environments/prod/network.tf"
    region = "us-east-1"
  }
}

module "network" {
  source      = "../../../modules/network"
  aws_region  = "us-east-1"
  project     = ""
  environment = "prod"
}