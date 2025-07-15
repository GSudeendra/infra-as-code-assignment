#!/bin/bash
set -e

# Set these to match your backend config
BUCKET="iac-remote-state-160071257600-dev"
DYNAMODB_TABLE="iac-terraform-locks-dev"
OIDC_URL="https://token.actions.githubusercontent.com"

AWS_PROFILE="twbeach"
AWS_REGION="us-east-1"

echo "Cleaning up remote state resources..."

# Delete S3 bucket (empty first)
if aws s3api head-bucket --bucket "$BUCKET" --region "$AWS_REGION" --profile "$AWS_PROFILE" 2>/dev/null; then
  echo "Emptying and deleting S3 bucket: $BUCKET"
  aws s3 rm "s3://$BUCKET" --recursive --region "$AWS_REGION" --profile "$AWS_PROFILE" || true
  aws s3api delete-bucket --bucket "$BUCKET" --region "$AWS_REGION" --profile "$AWS_PROFILE" || true
else
  echo "S3 bucket $BUCKET does not exist."
fi

# Delete DynamoDB table
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" --profile "$AWS_PROFILE" 2>/dev/null; then
  echo "Deleting DynamoDB table: $DYNAMODB_TABLE"
  aws dynamodb delete-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" --profile "$AWS_PROFILE" || true
else
  echo "DynamoDB table $DYNAMODB_TABLE does not exist."
fi

# Delete OIDC provider
OIDC_ARN=$(aws iam list-open-id-connect-providers --profile "$AWS_PROFILE" | grep -o "arn:aws:iam::[0-9]*:oidc-provider/$(echo $OIDC_URL | sed 's|https://||')" || true)
if [ -n "$OIDC_ARN" ]; then
  echo "Deleting OIDC provider: $OIDC_ARN"
  aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" --profile "$AWS_PROFILE" || true
else
  echo "OIDC provider for $OIDC_URL does not exist."
fi

echo "Cleanup complete." 