data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
        }
    }
}

data "aws_iam_policy_document" "codebuild_role_policy" {
  statement {
    actions   = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "ssm:*",
            "cloudformation:*",
            "s3:*",
            "apigateway:*",
            "lambda:*",
            "codebuild:*"
        ]
    resources = ["*"]
  }
}

data "aws_ssm_parameter" "github_token" {
  name = "/app/github_token"
}