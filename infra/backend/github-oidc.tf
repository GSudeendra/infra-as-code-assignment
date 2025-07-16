data "aws_caller_identity" "current" {}

# Dedicated IAM Role for GitHub Actions OIDC (CI/CD only)
resource "aws_iam_role" "github_oidc" {
  name = "github-actions-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:GSudeendra/infra-as-code-assignment:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
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
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:GSudeendra/infra-as-code-assignment:*"
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
          "dynamodb:ListTables",
          "dynamodb:TagResource"
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

resource "aws_iam_role_policy" "github_oidc_policy" {
  name = "github-actions-oidc-policy"
  role = aws_iam_role.github_oidc.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "dynamodb:*",
          "cloudwatch:*",
          "logs:*",
          "lambda:*",
          "apigateway:*",
          "iam:PassRole",
          "iam:GetOpenIDConnectProvider",
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "iam:CreatePolicy",
          "iam:TagRole",
          "iam:TagPolicy",
          "iam:DeleteRole",
          "iam:DeletePolicy",
          "iam:DetachRolePolicy",
          "iam:GetRole",
          "iam:GetPolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListPolicies"
        ]
        Resource = [
          "*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        ]
      }
    ]
  })
}

# Policy to allow creation of the GitHub Actions OIDC role
resource "aws_iam_policy" "allow_create_github_oidc_role" {
  name        = "allow-create-github-oidc-role"
  description = "Allow creation of the GitHub Actions OIDC role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-oidc-role"
      }
    ]
  })
}

# Attach the allow_create_github_oidc_role policy to the Terraform execution role
resource "aws_iam_role_policy_attachment" "attach_create_github_oidc_role" {
  role       = var.terraform_execution_role_name # Set this variable to your Terraform execution role name
  policy_arn = aws_iam_policy.allow_create_github_oidc_role.arn
} 