locals {
  name        = "${var.project}-${var.environment}-postgres"
  db_username = "ukiyo"
  db_password = random_password.password.result

  tags = {
    Environment = var.environment
  }
}

resource "random_password" "password" {
  length  = 26
  special = false
}

################################################################################
# RDS Aurora Module - PostgreSQL Serverless V2
################################################################################

data "aws_rds_engine_version" "postgresql" {
  engine  = "aurora-postgresql"
  version = "13.6"
}

module "rds-aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "7.2.2"

  name            = local.name
  database_name   = "odin"
  master_username = local.db_username
  master_password = local.db_password

  engine         = data.aws_rds_engine_version.postgresql.engine
  engine_mode    = "provisioned"
  engine_version = data.aws_rds_engine_version.postgresql.version
  instance_class = var.database_instance_class
  instances      = var.database_instances

  # When using RDS Proxy w/ IAM auth - Database must be username/password auth, not IAM
  iam_database_authentication_enabled = false

  vpc_id                 = var.vpc.vpc_id
  subnets                = var.vpc.database_subnets
  create_security_group  = false
  vpc_security_group_ids = [module.rds_proxy_sg.security_group_id]

  monitoring_interval = 60

  storage_encrypted   = true
  apply_immediately   = true
  skip_final_snapshot = true

  create_monitoring_role = false

  db_subnet_group_name            = var.vpc.database_subnet_group_name # Created by VPC module
  create_db_subnet_group          = false
  db_parameter_group_name         = aws_db_parameter_group.database.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.database.id

  serverlessv2_scaling_configuration = {
    min_capacity = 2
    max_capacity = 10
  }

  tags = local.tags

  # instance_class = "db.serverless"
  # instances      = {
  #   one = {}
  #   two = {}
  # }
}

resource "aws_db_parameter_group" "database" {
  name        = "${var.environment}-${var.project}-parameter-group"
  family      = "aurora-postgresql13"
  description = "${var.environment} ${var.project} parameter-group"
  tags        = local.tags
}

resource "aws_rds_cluster_parameter_group" "database" {
  name        = "${var.environment}-${var.project}-cluster-parameter-group"
  family      = "aurora-postgresql13"
  description = "${var.environment} ${var.project} cluster parameter-group"
  tags        = local.tags
}

# module "rds" {
#   source  = "terraform-aws-modules/rds-aurora/aws"
#   version = "~> 6.0"

#   name            = local.name
#   database_name   = "odin"
#   master_username = local.db_username
#   master_password = local.db_password

#   # When using RDS Proxy w/ IAM auth - Database must be username/password auth, not IAM
#   iam_database_authentication_enabled = false

#   engine         = "aurora-postgresql"
#   engine_version = "12.7"
#   instance_class = var.database_instance_class
#   instances      = var.database_instances

#   storage_encrypted   = true
#   apply_immediately   = true
#   skip_final_snapshot = true

#   create_monitoring_role = false

#   vpc_id                 = var.vpc.vpc_id
#   subnets                = var.vpc.database_subnets
#   create_security_group  = false
#   vpc_security_group_ids = [module.rds_proxy_sg.security_group_id]

#   db_subnet_group_name            = var.vpc.database_subnet_group_name # Created by VPC module
#   create_db_subnet_group          = false
#   db_parameter_group_name         = aws_db_parameter_group.database.id
#   db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.database.id

#   tags = local.tags
# }

# resource "aws_db_parameter_group" "database" {
#   name        = "${var.environment}-${var.project}-parameter-group"
#   family      = "aurora-postgresql12"
#   description = "${var.environment} ${var.project} parameter group"

#   tags = local.tags
# }

# resource "aws_rds_cluster_parameter_group" "database" {
#   name        = "${var.environment}-${var.project}-cluster-parameter-group"
#   family      = "aurora-postgresql12"
#   description = "${var.environment} ${var.project} cluster parameter group"

#   tags = local.tags
# }

################################################################################
# Secrets - DB user passwords
################################################################################

data "aws_kms_alias" "secretsmanager" {
  name = "alias/aws/secretsmanager"
}

resource "aws_secretsmanager_secret" "superuser" {
  name        = "${var.project}-${var.environment}-odin"
  description = "Secrets for app odin"
  kms_key_id  = data.aws_kms_alias.secretsmanager.id

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "superuser" {
  secret_id     = aws_secretsmanager_secret.superuser.id
  secret_string = jsonencode({
    db_username = local.db_username
    db_password = local.db_password
  })
}

################################################################################
# RDS Proxy
################################################################################

module "rds_proxy_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${local.name}-rds-proxy-sg"
  description = "${local.name} PostgreSQL RDS Proxy security group"
  vpc_id      = var.vpc.vpc_id

  revoke_rules_on_delete = true

  ingress_with_cidr_blocks = [
    {
      description = "Private subnet PostgreSQL access"
      rule        = "postgresql-tcp"
      cidr_blocks = join(",", var.vpc.private_subnets_cidr_blocks)
    }
  ]

  egress_with_cidr_blocks = [
    {
      description = "Database subnet PostgreSQL access"
      rule        = "postgresql-tcp"
      cidr_blocks = join(",", var.vpc.database_subnets_cidr_blocks)
    },
  ]

  tags = local.tags
}

module "rds_proxy" {
  source = "clowdhaus/rds-proxy/aws"

  create_proxy = true

  name                   = "${local.name}-rds-proxy"
  iam_role_name          = "${local.name}-rds-proxy-role"
  vpc_subnet_ids         = var.vpc.private_subnets
  vpc_security_group_ids = [module.rds_proxy_sg.security_group_id]

  db_proxy_endpoints = {
    read_write = {
      name                   = "${local.name}-read-write-endpoint"
      vpc_subnet_ids         = var.vpc.private_subnets
      vpc_security_group_ids = [module.rds_proxy_sg.security_group_id]
      tags                   = local.tags
    },
    read_only = {
      name                   = "${local.name}-read-only-endpoint"
      vpc_subnet_ids         = var.vpc.private_subnets
      vpc_security_group_ids = [module.rds_proxy_sg.security_group_id]
      target_role            = "READ_ONLY"
      tags                   = local.tags
    }
  }

  secrets = {
    "${var.project}-${var.environment}-odin" = {
      description = aws_secretsmanager_secret.superuser.description
      arn         = aws_secretsmanager_secret.superuser.arn
      kms_key_id  = aws_secretsmanager_secret.superuser.kms_key_id
    }
  }

  engine_family               = "POSTGRESQL"
  debug_logging               = false
  manage_log_group            = true
  log_group_retention_in_days = 1

  # Target Aurora cluster
  target_db_cluster     = true
  db_cluster_identifier = module.rds-aurora.cluster_id

  tags = local.tags
}