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

variable "subdomain_name" {
  description = "subdomain"
  default     = "sanctuary-dev"
}

variable "aws_certificate_arn" {
  description = "aws acm certificate arn"
}