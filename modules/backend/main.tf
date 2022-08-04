locals {
  stack_name = "${var.project}-${var.environment}-application"
}

data "cloudflare_zones" "default" {
  filter {
    name = var.domain_name
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "${local.stack_name}-lambda-sg"
  description = "Security Group for lambda"
  vpc_id      = var.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.vpc.private_subnets_cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${local.stack_name}-lambda-sg"
  }
}

resource "null_resource" "app" {
  triggers = {
    s3_bucket        = var.artifacts_bucket.id
    stack_name       = local.stack_name
    sec_group_ids    = join(",", aws_security_group.lambda_sg.*.id)
    subnet_ids       = join(",", var.vpc.private_subnets)
    domain_name      = "${var.subdomain_name_backend}.${var.domain_name}"
    target_stage     = var.environment
    project          = var.project
    artifact_version = var.artifact_version
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      cd ../../../../api
      sam build
      sam package --s3-bucket ${self.triggers.s3_bucket} --s3-prefix ${local.stack_name}/${self.triggers.artifact_version}
      sam deploy --stack-name ${self.triggers.stack_name} --s3-bucket ${self.triggers.s3_bucket} --s3-prefix ${local.stack_name}/${self.triggers.artifact_version} --capabilities CAPABILITY_IAM --parameter-overrides TargetStage=${self.triggers.project} TargetStage=${self.triggers.target_stage} DomainName=${self.triggers.domain_name} VPCSecurityGroupIDs=${self.triggers.sec_group_ids} VPCSubnetIDs=${self.triggers.subnet_ids} AcmCertificateArn=${var.aws_certificate_arn} Project=${var.project}
    EOT
  }
  depends_on = [aws_security_group.lambda_sg]
}

resource "null_resource" "get_api_gateway_endpoint" {
  triggers = {
    stack_name = local.stack_name
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "aws apigateway get-domain-name --domain-name ${var.subdomain_name_backend}.${var.domain_name} | jq '.regionalDomainName' | sed 's/\"//g' > gateway_endpoint.txt"
  }
  depends_on = [null_resource.app]
}

data "local_file" "api_gateway_endpoint" {
  filename   = "gateway_endpoint.txt"
  depends_on = [null_resource.get_api_gateway_endpoint]
}

resource "cloudflare_record" "api_gateway_endpoint" {
  depends_on = [data.local_file.api_gateway_endpoint]
  name       = var.subdomain_name_backend
  value      = data.local_file.api_gateway_endpoint.content
  type       = "CNAME"
  proxied    = false
  zone_id    = lookup(data.cloudflare_zones.default.zones[0], "id")
}