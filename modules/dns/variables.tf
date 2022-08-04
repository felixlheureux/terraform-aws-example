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

variable "domain_name" {
  description = "domain"
  default     = "childrenofukiyo.com"
}