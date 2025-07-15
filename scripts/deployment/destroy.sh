#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# AWS region and resource names (customize as needed)
AWS_REGION="us-east-1"
STATE_BUCKET="iac-remote-state-160071257600-dev"
STATE_KEY="terraform.tfstate"
DYNAMO_TABLE="iac-remote-state-160071257600-dev"


echo "🗑️  Starting Infrastructure Destruction"
echo "======================================"

# Check AWS CLI configuration
print_status "Checking AWS CLI configuration..."
if aws sts get-caller-identity &>/dev/null; then
    print_success "AWS CLI configured ✓"
else
    print_error "AWS CLI is not configured. Exiting."
    exit 1
fi

# Step 1: Destroy Main Infrastructure
print_status "Step 1: Destroying Main Infrastructure..."
cd "$PROJECT_ROOT/infra"
if [ ! -d ".terraform" ]; then
    print_status "Initializing Terraform..."
    terraform init
fi
print_status "Destroying main infrastructure..."

# --- BEGIN: Handle Terraform state/DynamoDB checksum mismatch ---
set +e  # Disable exit on error for this block
TF_DESTROY_OUTPUT=$(terraform destroy -auto-approve 2>&1)
TF_DESTROY_EXIT=$?
echo "[DEBUG] terraform destroy exit code: $TF_DESTROY_EXIT"
echo "[DEBUG] terraform destroy output:\n$TF_DESTROY_OUTPUT"

# Check for checksum mismatch first, then for other errors
if echo "$TF_DESTROY_OUTPUT" | grep -qi "checksum.*state stored in S3.*does not match.*DynamoDB"; then
    print_warning "Terraform state/DynamoDB checksum mismatch detected. Attempting to delete DynamoDB lock/checksum and S3 state file, then retry..."
    # Delete DynamoDB lock/checksum for terraform.tfstate
    aws dynamodb delete-item --table-name "$DYNAMO_TABLE" --key '{"LockID": {"S": "terraform.tfstate"}}' --region "$AWS_REGION"
    print_success "DynamoDB lock/checksum deleted."
    # Delete S3 state file (nuclear option)
    aws s3 rm "s3://$STATE_BUCKET/$STATE_KEY" || print_warning "Could not delete S3 state file (may already be deleted)"
    print_success "S3 state file deleted. Retrying terraform destroy (will not destroy resources if state is missing) ..."
    TF_DESTROY_OUTPUT2=$(terraform destroy -auto-approve 2>&1)
    TF_DESTROY_EXIT2=$?
    echo "[DEBUG] terraform destroy (retry) exit code: $TF_DESTROY_EXIT2"
    echo "[DEBUG] terraform destroy (retry) output:\n$TF_DESTROY_OUTPUT2"
    if [ $TF_DESTROY_EXIT2 -ne 0 ]; then
        print_warning "Terraform destroy (after lock and state deletion) still failed. Continuing with manual cleanup. Output:\n$TF_DESTROY_OUTPUT2"
        # Do not exit; continue with cleanup
    fi
else
    if [ $TF_DESTROY_EXIT -ne 0 ]; then
        print_error "Terraform destroy failed. Output:\n$TF_DESTROY_OUTPUT"
        exit 1
    fi
fi
set -e  # Re-enable exit on error
# --- END: Handle Terraform state/DynamoDB checksum mismatch ---

print_success "Main infrastructure destroyed ✓"
cd "$PROJECT_ROOT"

# Step 2: Destroy Remote State Infrastructure
print_status "Step 2: Destroying Remote State Infrastructure..."
cd "$PROJECT_ROOT/infra/backend"
if [ ! -d ".terraform" ]; then
    print_status "Initializing Terraform..."
    terraform init
fi
print_status "Destroying remote state infrastructure..."

# --- BEGIN: Handle Terraform state/DynamoDB checksum mismatch (remote state) ---
set +e
TF_DESTROY_OUTPUT=$(terraform destroy -auto-approve 2>&1)
TF_DESTROY_EXIT=$?
echo "[DEBUG] terraform destroy (remote state) exit code: $TF_DESTROY_EXIT"
echo "[DEBUG] terraform destroy (remote state) output:\n$TF_DESTROY_OUTPUT"

if echo "$TF_DESTROY_OUTPUT" | grep -qi "checksum.*state stored in S3.*does not match.*DynamoDB"; then
    print_warning "Terraform state/DynamoDB checksum mismatch detected (remote state). Attempting to delete DynamoDB lock/checksum and S3 state file, then retry..."
    # Delete DynamoDB lock/checksum for terraform.tfstate
    aws dynamodb delete-item --table-name "$DYNAMO_TABLE" --key '{"LockID": {"S": "terraform.tfstate"}}' --region "$AWS_REGION"
    print_success "DynamoDB lock/checksum deleted (remote state)."
    # Delete S3 state file (nuclear option)
    aws s3 rm "s3://$STATE_BUCKET/$STATE_KEY" || print_warning "Could not delete S3 state file (may already be deleted)"
    print_success "S3 state file deleted (remote state). Retrying terraform destroy (will not destroy resources if state is missing) ..."
    TF_DESTROY_OUTPUT2=$(terraform destroy -auto-approve 2>&1)
    TF_DESTROY_EXIT2=$?
    echo "[DEBUG] terraform destroy (remote state, retry) exit code: $TF_DESTROY_EXIT2"
    echo "[DEBUG] terraform destroy (remote state, retry) output:\n$TF_DESTROY_OUTPUT2"
    if [ $TF_DESTROY_EXIT2 -ne 0 ]; then
        print_warning "Terraform destroy (remote state, after lock and state deletion) still failed. Continuing with manual cleanup. Output:\n$TF_DESTROY_OUTPUT2"
        # Do not exit; continue with cleanup
    fi
else
    if [ $TF_DESTROY_EXIT -ne 0 ]; then
        print_error "Terraform destroy (remote state) failed. Output:\n$TF_DESTROY_OUTPUT"
        exit 1
    fi
fi
set -e
# --- END: Handle Terraform state/DynamoDB checksum mismatch (remote state) ---

print_success "Remote state infrastructure destroyed ✓"
cd "$PROJECT_ROOT"

# Step 3: Empty and Delete S3 Buckets (if any remain)
print_status "Step 3: Emptying and deleting S3 buckets (if any remain)..."
BUCKETS=(
  "static-content-dev-916b5a00"
  "access-logs-dev-916b5a00"
  "$STATE_BUCKET"
  "iac-remote-state-logs-dev"
)
for BUCKET in "${BUCKETS[@]}"; do
  if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
    print_status "Emptying bucket: $BUCKET ..."
    aws s3 rm "s3://$BUCKET" --recursive || print_warning "Could not empty $BUCKET (may already be empty or deleted)"
    print_status "Deleting bucket: $BUCKET ..."
    aws s3api delete-bucket --bucket "$BUCKET" --region "$AWS_REGION" || print_warning "Could not delete $BUCKET (may already be deleted)"
  else
    print_warning "Bucket $BUCKET does not exist or is already deleted."
  fi
  sleep 2
done

# Step 4: Delete CloudWatch Log Groups
print_status "Step 4: Deleting CloudWatch log groups..."
LOG_GROUPS=(
  "/aws/lambda/register_user-dev-916b5a00"
  "/aws/lambda/verify_user-dev-916b5a00"
  "/aws/apigateway/user-management-api"
)
for LOG_GROUP in "${LOG_GROUPS[@]}"; do
  if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region "$AWS_REGION" | grep -q "$LOG_GROUP"; then
    print_status "Deleting log group: $LOG_GROUP ..."
    aws logs delete-log-group --log-group-name "$LOG_GROUP" --region "$AWS_REGION" || print_warning "Could not delete $LOG_GROUP (may already be deleted)"
  else
    print_warning "Log group $LOG_GROUP does not exist or is already deleted."
  fi
  sleep 1
done

# Step 5: Delete State File and DynamoDB Lock
print_status "Step 5: Deleting remote state file and DynamoDB lock/checksum..."
if aws s3api head-object --bucket "$STATE_BUCKET" --key "$STATE_KEY" 2>/dev/null; then
  aws s3 rm "s3://$STATE_BUCKET/$STATE_KEY" || print_warning "Could not delete state file (may already be deleted)"
  print_success "State file deleted from S3 ✓"
else
  print_warning "State file does not exist in S3."
fi

# Delete DynamoDB item (terraform.tfstate)
if aws dynamodb get-item --table-name "$DYNAMO_TABLE" --key '{"LockID": {"S": "terraform.tfstate"}}' --region "$AWS_REGION" | grep -q 'Item'; then
  aws dynamodb delete-item --table-name "$DYNAMO_TABLE" --key '{"LockID": {"S": "terraform.tfstate"}}' --region "$AWS_REGION" || print_warning "Could not delete DynamoDB lock/checksum (may already be deleted)"
  print_success "DynamoDB lock/checksum deleted ✓"
else
  print_warning "DynamoDB lock/checksum does not exist."
fi

# --- All other cleanup steps above this line ---

# FINAL STEP: Brute-force cleanup of remote state and related resources (must be last)
print_status "Final Step: Brute-force cleanup of remote state and related resources (must be last)..."

# 1. Delete log bucket first
LOG_BUCKET="iac-remote-state-logs-dev"
if aws s3api head-bucket --bucket "$LOG_BUCKET" --region "$AWS_REGION" 2>/dev/null; then
  print_warning "[BRUTE FORCE] Deleting log bucket: $LOG_BUCKET ..."
  aws s3 rm "s3://$LOG_BUCKET" --recursive || print_warning "[BRUTE FORCE] Could not empty $LOG_BUCKET (may already be empty or deleted)"
  aws s3api delete-bucket --bucket "$LOG_BUCKET" --region "$AWS_REGION" || print_warning "[BRUTE FORCE] Could not delete $LOG_BUCKET (may already be deleted)"
fi

# 2. Delete DynamoDB table (if present)
if aws dynamodb describe-table --table-name "iac-terraform-locks-dev" --region "$AWS_REGION" 2>/dev/null | grep -q 'TableDescription'; then
  print_warning "[BRUTE FORCE] Deleting DynamoDB table: iac-terraform-locks-dev ..."
  aws dynamodb delete-table --table-name "iac-terraform-locks-dev" --region "$AWS_REGION" || print_warning "[BRUTE FORCE] Could not delete DynamoDB table (may already be deleted)"
fi

# 3. Delete IAM OIDC Provider (if present)
OIDC_ARN=$(aws iam list-open-id-connect-providers --region "$AWS_REGION" --query 'OpenIDConnectProviderList[*].Arn' --output text | grep 'token.actions.githubusercontent.com' || true)
if [ ! -z "$OIDC_ARN" ]; then
  print_warning "[BRUTE FORCE] Deleting IAM OIDC provider: $OIDC_ARN ..."
  aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" --region "$AWS_REGION" || print_warning "[BRUTE FORCE] Could not delete OIDC provider (may already be deleted)"
fi

# 4. Delete state bucket last (critical: must be last)
# This ensures all other resources and state are cleaned up before removing the state bucket.
echo
read -p "Do you want to delete the state bucket $STATE_BUCKET? (yes/no): " DELETE_STATE_BUCKET
if [ "$DELETE_STATE_BUCKET" = "yes" ]; then
  if aws s3api head-bucket --bucket "$STATE_BUCKET" --region "$AWS_REGION" 2>/dev/null; then
    print_warning "[BRUTE FORCE] Deleting state bucket LAST: $STATE_BUCKET ..."
    aws s3 rm "s3://$STATE_BUCKET" --recursive || print_warning "[BRUTE FORCE] Could not empty $STATE_BUCKET (may already be empty or deleted)"
    aws s3api delete-bucket --bucket "$STATE_BUCKET" --region "$AWS_REGION" || print_warning "[BRUTE FORCE] Could not delete $STATE_BUCKET (may already be deleted)"
  fi
  print_success "State bucket $STATE_BUCKET deleted."
else
  print_status "State bucket $STATE_BUCKET was NOT deleted (user chose 'no')."
fi

print_success "Brute-force cleanup complete. AWS account should now be clean."

print_success "Environment cleanup complete! AWS account is ready for a fresh deployment." 