terraform {
  backend "s3" {
    bucket = ""
    # The key definition changes following the environment
    key    = "environments/prod/database.tf"
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

module "database" {
  source                  = "../../../modules/database_cluster"
  aws_region              = "us-east-1"
  project                 = ""
  environment             = "prod"
  domain_name             = ""
  vpc                     = data.terraform_remote_state.network.outputs.vpc
  database_instance_class = "db.t3.medium"
  database_instances = {
       one = {}
       two = {}
  }
}