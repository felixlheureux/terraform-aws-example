variable "aws_region" {
  default = "us-east-1"
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

variable "vpc" {
  description = "vpc"
}

variable "database_instance_class" {
  description = "database instance class"
  default     = "db.t3.micro"
}