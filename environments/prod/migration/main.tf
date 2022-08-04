terraform {
  backend "s3" {
    bucket = ""
    # The key definition changes following the environment
    key    = "environments/prod/migration.tf"
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

module "migration" {
  source      = "../../../modules/migration"
  aws_region  = "us-east-1"
  project     = ""
  environment = "prod"
  vpc         = data.terraform_remote_state.network.outputs.vpc
}