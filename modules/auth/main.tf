locals {
  name   = "${var.project}-${var.environment}-user-pool"
  domain = "auth-${var.environment}.${var.domain_name}"

  tags = {
    Environment = var.environment
  }
}

data "cloudflare_zones" "domain" {
  filter {
    name = var.domain_name
  }
}

################################################################################
# Cognito Module
################################################################################

resource "aws_cognito_user_pool" "user_pool" {
  name = local.name

  alias_attributes = ["preferred_username", "email", "phone_number"]

  username_configuration {
    case_sensitive = false
  }

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "preferred_username"
    required            = true
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  mfa_configuration = "OFF"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }

    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  lifecycle {
    ignore_changes = [
      schema ### AWS doesn't allow schema updates, so every build will re-create the user pool unless we ignore this bit
    ]
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name = "${var.project}-${var.environment}-user-pool-client"

  user_pool_id                  = aws_cognito_user_pool.user_pool.id
  generate_secret               = true
  refresh_token_validity        = 30
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows           = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = var.subdomain_name
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "cloudflare_record" "cname" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = local.domain
  value   = "${var.subdomain_name}.auth.${var.aws_region}.amazoncognito.com"
  type    = "CNAME"
  ttl     = 1
  proxied = false
}