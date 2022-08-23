locals {
  name        = "${var.project}-${var.environment}-postgres"
  db_username = "test"
  db_password = random_password.password.result

  tags = {
    Environment = var.environment
  }
}

resource "random_password" "password" {
  length  = 25
  special = false
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = local.name
  description = "Odin PostgreSQL dev security group"
  vpc_id      = var.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = join(",", var.vpc.private_subnets_cidr_blocks)
    },
  ]

  tags = local.tags
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"

  db_name  = "odin"
  username = local.db_username
  password = local.db_password

  # When using RDS Proxy w/ IAM auth - Database must be username/password auth, not IAM
  iam_database_authentication_enabled = false

  identifier            = local.name
  engine                = "postgres"
  engine_version        = "12.7"
  family                = "postgres12"
  major_engine_version  = "12"
  port                  = 5432
  instance_class        = var.database_instance_class
  allocated_storage     = 5
  max_allocated_storage = 10
  apply_immediately     = true

  create_monitoring_role = false

  vpc_security_group_ids = [module.rds_sg.security_group_id]
  db_subnet_group_name   = var.vpc.database_subnet_group
  subnet_ids             = var.vpc.database_subnets
  multi_az               = false

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 0
  deletion_protection     = false

  tags = local.tags
}

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
