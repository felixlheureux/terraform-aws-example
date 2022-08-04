terraform {
  backend "s3" {
    bucket = ""
    # The key definition changes following the environment
    key    = "environments/dev/migration.tf"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = ""
    key    = "environments/dev/network.tf"
    region = "us-east-1"
  }
}

module "migration" {
  source      = "../../../modules/migration"
  aws_region  = "us-east-1"
  project     = ""
  environment = "dev"
  vpc         = data.terraform_remote_state.network.outputs.vpc
}