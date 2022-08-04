locals {
  name = "${var.project}-${var.environment}-migration"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "${local.name}-lambda-iam"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${local.name}-lambda-policy"
  path        = "/"
  description = "IAM policy migration lambda"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_security_group" "lambda_sg" {
  name        = "${local.name}-lambda-sg"
  description = "Security Group for lambda"
  vpc_id      = var.vpc.vpc_id

  egress {
    description = "Database access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.vpc.database_subnets_cidr_blocks
  }

  tags = {
    Name = "${local.name}-lambda-sg"
  }
}

resource "aws_cloudwatch_log_group" "lambda_lg" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 1
}

resource "aws_lambda_function" "lambda" {
  filename      = "main.zip"
  function_name = local.name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main"
  memory_size   = 128
  timeout       = 60

  vpc_config {
    subnet_ids         = var.vpc.private_subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  source_code_hash = filebase64sha256("main.zip")

  runtime = "go1.x"

  environment {
    variables = {
      DB_HOST = ""
      DB_PORT = ""
      DB_NAME = ""
      DB_USER = ""
      DB_PASS = ""
    }
  }
}