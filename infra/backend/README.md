# Backend Infrastructure Module

This module provisions the foundational AWS resources required for secure, automated CI/CD with GitHub Actions and Terraform.

## What This Module Does
- **Registers the GitHub Actions OIDC provider** with AWS for secure, short-lived authentication.
- **Creates an IAM role** (`iac-github-actions-role-dev`) that GitHub Actions can assume via OIDC for all CI/CD operations.
- **Attaches least-privilege policies** to the role for managing S3, DynamoDB, Lambda, API Gateway, CloudWatch, and IAM resources.
- **Provides outputs** for the remote state S3 bucket, DynamoDB table, and IAM role ARN.

## Key Resources
| Resource Type | Name/Pattern | Purpose |
|--------------|-------------|---------|
| OIDC Provider | `token.actions.githubusercontent.com` | Allows GitHub Actions to authenticate to AWS |
| IAM Role | `iac-github-actions-role-dev` | Assumed by GitHub Actions for CI/CD |
| IAM Policies | Inline/attached | Permissions for Terraform to manage infra |
| S3 Bucket | `iac-remote-state-...` | Stores Terraform remote state |
| DynamoDB Table | `iac-terraform-locks-...` | State locking for Terraform |

## When/Why You Might Change Values
- **OIDC Provider URL/Thumbprint:** Only if GitHub changes their OIDC endpoint or SSL certificate.
- **IAM Role Name:** If you change your project prefix or environment (e.g., for staging/prod).
- **Trust Policy (repo/org):** If you move your repo or change your GitHub organization/user.
- **Policy Actions/Resources:** If you add new AWS services or want to further restrict/expand permissions.
- **S3/DynamoDB Names:** If you want to use different naming conventions or environments.

## Best Practices
- **Manage all changes via Terraform** for auditability and reproducibility.
- **Review IAM permissions regularly** to ensure least privilege.
- **Update the OIDC provider thumbprint** if GitHub rotates their SSL certificate.
- **Keep this README up to date** as your infrastructure evolves.

## Outputs
- `s3_bucket_name` and `s3_bucket_arn`: Remote state bucket
- `dynamodb_table_name` and `dynamodb_table_arn`: State lock table
- `github_actions_role_arn`: IAM role for GitHub Actions

---
For more details, see the main project README or contact the project maintainer. 