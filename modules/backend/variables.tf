variable "aws_region" {
  default = "us-east-1"
}

variable "cloudflare_email" {
  description = "cloudflare email for api key"
  sensitive   = true
}

variable "cloudflare_api_key" {
  description = "cloudflare api key"
  sensitive   = true
}

variable "project" {
  description = "project name"
  default     = "childrenofukiyo"
}

variable "environment" {
  description = "environment"
  default     = "dev"
}

variable "domain_name" {
  description = "domain"
  default     = "childrenofukiyo.com"
}

variable "subdomain_name_backend" {
  description = "subdomain for backend/api gateway"
  default     = "api-dev"
}

variable "vpc" {
  description = "vpc"
}

variable "aws_certificate_arn" {
  description = "aws acm certificate arn"
}

variable "artifacts_bucket" {
  description = "artifacts bucket"
}

variable "artifact_version" {
  description = "artifacts version"
}