data "aws_caller_identity" "current" {}

# OIDC provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = var.tags
}

# IAM role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "${var.project_prefix}-github-actions-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:sudeendrag/infra-as-code-assignment:*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for GitHub Actions
resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project_prefix}-github-actions-policy-${var.environment}"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketVersioning",
          "s3:PutBucketEncryption",
          "s3:PutBucketAcl",
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:DeleteBucketPolicy"
        ]
        Resource = [
          "arn:aws:s3:::*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:CreateTable",
          "dynamodb:DeleteTable",
          "dynamodb:DescribeTable",
          "dynamodb:ListTables"
        ]
        Resource = [
          "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "iam:*",
          "cloudfront:*",
          "route53:*",
          "acm:*",
          "logs:*",
          "lambda:*",
          "apigateway:*",
          "execute-api:*"
        ]
        Resource = "*"
      }
    ]
  })
} 