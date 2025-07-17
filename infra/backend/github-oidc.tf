data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_prefix}-github-actions-role-sg-${var.environment}"

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

resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project_prefix}-github-actions-policy-${var.environment}"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # KMS (scoped to all keys in this account/region)
      {
        Effect = "Allow"
        Action = [
          "kms:TagResource",
          "kms:UntagResource",
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:EnableKeyRotation",
          "kms:PutKeyPolicy",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:DisableKeyRotation",
          "kms:DeleteKey",
          "kms:ListResourceTags",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = [
          "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
        ]
      },
      # S3 (all project buckets)
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket",
          "s3:GetBucketLocation", "s3:GetBucketVersioning", "s3:CreateBucket",
          "s3:DeleteBucket", "s3:PutBucketVersioning", "s3:PutBucketEncryption",
          "s3:PutBucketAcl", "s3:PutBucketPolicy", "s3:GetBucketPolicy", "s3:DeleteBucketPolicy",
          "s3:PutObjectAcl", "s3:GetObjectAcl", "s3:ListAllMyBuckets"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_prefix}-*",
          "arn:aws:s3:::${var.project_prefix}-*/*"
        ]
      },
      # DynamoDB (all project tables)
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem",
          "dynamodb:CreateTable", "dynamodb:DeleteTable", "dynamodb:DescribeTable",
          "dynamodb:ListTables", "dynamodb:TagResource", "dynamodb:Scan", "dynamodb:UpdateItem"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project_prefix}-*"
        ]
      },
      # Lambda (all functions in this account/region)
      {
        Effect = "Allow"
        Action = ["lambda:*"]
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:*"
      },
      # API Gateway (all)
      {
        Effect = "Allow"
        Action = ["apigateway:*", "execute-api:*"]
        Resource = "*"
      },
      # CloudWatch Logs & CloudWatch (all)
      {
        Effect = "Allow"
        Action = ["logs:*", "cloudwatch:*"]
        Resource = "*"
      },
      # X-Ray (all)
      {
        Effect = "Allow"
        Action = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
        Resource = "*"
      },
      # IAM (least privilege for OIDC/role management)
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole", "iam:CreateRole", "iam:DeleteRole", "iam:UpdateRole", "iam:PassRole",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:PutRolePolicy", "iam:DeleteRolePolicy",
          "iam:CreatePolicy", "iam:DeletePolicy", "iam:GetPolicy", "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies", "iam:ListPolicies", "iam:TagRole", "iam:TagPolicy",
          "iam:GetOpenIDConnectProvider"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_oidc_policy" {
  name = "github-actions-oidc-policy"
  role = aws_iam_role.github_actions.id

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
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "kms:TagResource",
          "lambda:TagResource",
          "logs:DescribeLogGroups",
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:EnableKeyRotation",
          "kms:PutKeyPolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "kms:GetKeyRotationStatus", "kms:ListKeys", "kms:ListAliases", "kms:GetKeyPolicy", "kms:PutKeyPolicy", "kms:DisableKeyRotation", "kms:DeleteKey", "kms:UntagResource",
          "kms:ListResourceTags"
        ]
        Resource = [
          "*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        ]
      }
    ]
  })
}

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

resource "aws_iam_role_policy_attachment" "attach_create_github_oidc_role" {
  role       = var.terraform_execution_role_name
  policy_arn = aws_iam_policy.allow_create_github_oidc_role.arn
}