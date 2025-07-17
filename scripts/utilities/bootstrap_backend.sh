#!/bin/bash

set -e

PROJECT_NAME="iac-user-management"
ENVIRONMENT="dev"
AWS_REGION="us-east-1"
S3_BUCKET_NAME="${PROJECT_NAME}-state-${ENVIRONMENT}"
DYNAMODB_TABLE_NAME="${PROJECT_NAME}-lock-table-${ENVIRONMENT}"
OIDC_ROLE_NAME="${PROJECT_NAME}-github-actions-oidc-role"

# Get GitHub repo information - use current origin if not provided
GITHUB_REPO=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
if [ -z "$GITHUB_REPO" ]; then
  echo "Could not determine GitHub repo. Please enter your GitHub repo (format: username/repo-name):"
  read GITHUB_REPO
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔑 Starting Admin Bootstrap for Terraform Backend"
echo "==============================================="
echo "GitHub Repository: $GITHUB_REPO"

print_status "Checking AWS CLI configuration..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    print_success "AWS CLI configured ✓"
else
    print_error "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# S3 Bucket
if ! aws s3api head-bucket --bucket "$S3_BUCKET_NAME" 2>/dev/null; then
    print_status "Creating S3 bucket: $S3_BUCKET_NAME"
    if [ "$AWS_REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "$S3_BUCKET_NAME" --region "$AWS_REGION"
    else
        aws s3api create-bucket --bucket "$S3_BUCKET_NAME" --region "$AWS_REGION" --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi

    # Enable versioning
    aws s3api put-bucket-versioning --bucket "$S3_BUCKET_NAME" --versioning-configuration Status=Enabled

    # Enable server-side encryption
    aws s3api put-bucket-encryption \
      --bucket "$S3_BUCKET_NAME" \
      --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

    print_success "S3 bucket created: $S3_BUCKET_NAME"
else
    print_status "S3 bucket already exists: $S3_BUCKET_NAME"
fi

# DynamoDB Table
if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE_NAME" --region "$AWS_REGION" 2>/dev/null; then
    print_status "Creating DynamoDB table: $DYNAMODB_TABLE_NAME"
    aws dynamodb create-table \
      --table-name "$DYNAMODB_TABLE_NAME" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region "$AWS_REGION"
    print_success "DynamoDB table created: $DYNAMODB_TABLE_NAME"
else
    print_status "DynamoDB table already exists: $DYNAMODB_TABLE_NAME"
fi

# OIDC Provider
OIDC_PROVIDER_URL="token.actions.githubusercontent.com"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
OIDC_PROVIDER_ARN="arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDC_PROVIDER_URL"

if ! aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[*].Arn' --output text | grep -q "$OIDC_PROVIDER_URL"; then
    print_status "Creating GitHub OIDC provider: $OIDC_PROVIDER_URL"
    aws iam create-open-id-connect-provider \
      --url "https://$OIDC_PROVIDER_URL" \
      --client-id-list "sts.amazonaws.com" \
      --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" \
      --region "$AWS_REGION"
    print_success "OIDC provider created: $OIDC_PROVIDER_URL"
else
    print_status "OIDC provider already exists: $OIDC_PROVIDER_URL"
fi

# OIDC Role
if ! aws iam get-role --role-name "$OIDC_ROLE_NAME" 2>/dev/null; then
    print_status "Creating OIDC IAM role: $OIDC_ROLE_NAME"
    TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$OIDC_PROVIDER_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:$GITHUB_REPO:*"
        }
      }
    }
  ]
}
EOF
)
    aws iam create-role \
      --role-name "$OIDC_ROLE_NAME" \
      --assume-role-policy-document "$TRUST_POLICY" \
      --description "OIDC role for GitHub Actions CI/CD pipeline" \
      --region "$AWS_REGION"

    # Create IAM policy for the role
    POLICY_DOCUMENT=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "dynamodb:*",
        "logs:*",
        "lambda:*",
        "apigateway:*",
        "iam:GetRole",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
EOF
)
    aws iam put-role-policy \
      --role-name "$OIDC_ROLE_NAME" \
      --policy-name "${OIDC_ROLE_NAME}-policy" \
      --policy-document "$POLICY_DOCUMENT"

    print_success "OIDC IAM role created: $OIDC_ROLE_NAME"
else
    print_status "OIDC IAM role already exists: $OIDC_ROLE_NAME"

    # Update the trust policy in case the repo name changed
    print_status "Updating trust policy for: $OIDC_ROLE_NAME"
    TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$OIDC_PROVIDER_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:$GITHUB_REPO:*"
        }
      }
    }
  ]
}
EOF
)
    aws iam update-assume-role-policy \
      --role-name "$OIDC_ROLE_NAME" \
      --policy-document "$TRUST_POLICY"
    print_success "Trust policy updated for: $OIDC_ROLE_NAME"
fi

# Output important information
echo ""
echo "=============================================================="
echo "Configuration values to use in GitHub Actions and Terraform:"
echo "=============================================================="
echo "ACCOUNT_ID: $ACCOUNT_ID"
echo "S3_BUCKET_NAME: $S3_BUCKET_NAME"
echo "DYNAMODB_TABLE_NAME: $DYNAMODB_TABLE_NAME"
echo "GITHUB_OIDC_ROLE_ARN: arn:aws:iam::$ACCOUNT_ID:role/$OIDC_ROLE_NAME"
echo "AWS_REGION: $AWS_REGION"
echo "=============================================================="
echo ""

print_success "Admin bootstrap complete! You can now run the CI/CD pipeline."
