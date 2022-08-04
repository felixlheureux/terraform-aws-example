resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.project}-artifacts"
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_user" "github" {
  name = "${var.project}-github"
}

resource "aws_iam_user_policy" "github" {
  name = "${var.project}-github"
  user = aws_iam_user.github.name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "*",
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
  })
}