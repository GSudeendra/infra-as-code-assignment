#!/bin/bash
set -e

# Variables (edit as needed)
AWS_PROFILE=${AWS_PROFILE:-twbeach}
AWS_REGION=${AWS_REGION:-us-east-1}
BUCKET_NAME="iac-remote-state-dev"
DYNAMODB_TABLE="iac-terraform-locks-dev"
OIDC_PROVIDER_URL="https://token.actions.githubusercontent.com"

# Delete S3 bucket and all its contents
if aws s3api head-bucket --bucket "$BUCKET_NAME" --profile "$AWS_PROFILE" 2>/dev/null; then
  echo "Deleting all objects in S3 bucket: $BUCKET_NAME"
  aws s3 rm s3://$BUCKET_NAME --recursive --profile "$AWS_PROFILE"
  echo "Deleting S3 bucket: $BUCKET_NAME"
  aws s3api delete-bucket --bucket $BUCKET_NAME --region $AWS_REGION --profile "$AWS_PROFILE"
else
  echo "S3 bucket $BUCKET_NAME does not exist."
fi

# Delete DynamoDB table
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" --profile "$AWS_PROFILE" 2>/dev/null; then
  echo "Deleting DynamoDB table: $DYNAMODB_TABLE"
  aws dynamodb delete-table --table-name $DYNAMODB_TABLE --region $AWS_REGION --profile "$AWS_PROFILE"
else
  echo "DynamoDB table $DYNAMODB_TABLE does not exist."
fi

# Delete OIDC provider
OIDC_ARN=$(aws iam list-open-id-connect-providers --profile "$AWS_PROFILE" | jq -r '.OpenIDConnectProviderList[] | select(.Arn | contains("token.actions.githubusercontent.com")) | .Arn')
if [ -n "$OIDC_ARN" ]; then
  echo "Deleting OIDC provider: $OIDC_ARN"
  aws iam delete-open-id-connect-provider --open-id-connect-provider-arn $OIDC_ARN --profile "$AWS_PROFILE"
else
  echo "OIDC provider for $OIDC_PROVIDER_URL does not exist."
fi

echo "Cleanup complete." 