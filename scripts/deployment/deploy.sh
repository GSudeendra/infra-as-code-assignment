#!/bin/bash

set -e

# === Production-level resource names ===
PROJECT_NAME="iac-user-management"
ENVIRONMENT="prod"
AWS_REGION="us-east-1"
S3_BUCKET_NAME="${PROJECT_NAME}-state-${ENVIRONMENT}"
DYNAMODB_TABLE_NAME="${PROJECT_NAME}-lock-table-${ENVIRONMENT}"
OIDC_ROLE_NAME="${PROJECT_NAME}-github-actions-oidc-role"

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

echo "🚀 Starting Infrastructure Deployment"
echo "====================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

print_status "Checking AWS CLI configuration..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    print_success "AWS CLI configured ✓"
else
    print_error "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# --- Optional Admin Bootstrap Section ---
if [ "$BOOTSTRAP_ADMIN" = "1" ]; then
  print_status "[ADMIN] Checking and bootstrapping foundational resources..."

  # S3 Bucket
  if ! aws s3api head-bucket --bucket "$S3_BUCKET_NAME" 2>/dev/null; then
    print_status "[ADMIN] Creating S3 bucket: $S3_BUCKET_NAME"
    aws s3api create-bucket --bucket "$S3_BUCKET_NAME" --region "$AWS_REGION" --create-bucket-configuration LocationConstraint="$AWS_REGION"
  else
    print_status "[ADMIN] S3 bucket already exists: $S3_BUCKET_NAME"
  fi

  # DynamoDB Table
  if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE_NAME" --region "$AWS_REGION" 2>/dev/null; then
    print_status "[ADMIN] Creating DynamoDB table: $DYNAMODB_TABLE_NAME"
    aws dynamodb create-table \
      --table-name "$DYNAMODB_TABLE_NAME" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region "$AWS_REGION"
  else
    print_status "[ADMIN] DynamoDB table already exists: $DYNAMODB_TABLE_NAME"
  fi

  # OIDC Role (skipped if exists)
  if ! aws iam get-role --role-name "$OIDC_ROLE_NAME" 2>/dev/null; then
    print_status "[ADMIN] Please create the OIDC IAM role: $OIDC_ROLE_NAME manually or with a dedicated script."
  else
    print_status "[ADMIN] OIDC IAM role already exists: $OIDC_ROLE_NAME"
  fi

  export S3_BUCKET_NAME
  export DYNAMODB_TABLE_NAME
fi
# --- End Admin Bootstrap Section ---

S3_BUCKET="$S3_BUCKET_NAME"
DYNAMODB_TABLE="$DYNAMODB_TABLE_NAME"
TERRAFORM_EXECUTION_ROLE_NAME="$OIDC_ROLE_NAME"

if [ -z "$S3_BUCKET" ] || [ -z "$DYNAMODB_TABLE" ]; then
    print_error "S3_BUCKET_NAME and DYNAMODB_TABLE_NAME must be set as environment variables."
    exit 1
fi

print_status "Step 1: Updating Backend Configuration..."
cd "$PROJECT_ROOT/infra"

cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "$S3_BUCKET"
    key            = "terraform.tfstate"
    region         = "$AWS_REGION"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF

print_success "Backend configuration updated ✓"

print_status "Step 2: Building Lambda ZIPs..."
cd "$PROJECT_ROOT/infra/modules/lambda"

if [ -f "$PROJECT_ROOT/src/register_user.py" ]; then
  echo "Building register_user from $PROJECT_ROOT/src/register_user.py → register_user.zip"
  zip -j register_user.zip "$PROJECT_ROOT/src/register_user.py"
else
  print_warning "register_user.py not found, skipping zip."
fi

if [ -f "$PROJECT_ROOT/src/verify_user.py" ]; then
  echo "Building verify_user from $PROJECT_ROOT/src/verify_user.py → verify_user.zip"
  zip -j verify_user.zip "$PROJECT_ROOT/src/verify_user.py"
else
  print_warning "verify_user.py not found, skipping zip."
fi

print_success "Lambda ZIPs built ✓"

cd "$PROJECT_ROOT/infra"

print_status "Step 3: Deploying Main Infrastructure..."

print_status "Initializing Terraform..."
terraform init

print_status "Planning main infrastructure..."
terraform plan -out=tfplan

print_status "Applying main infrastructure..."
terraform apply -auto-approve tfplan

API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")

print_success "Main infrastructure deployed ✓"

print_status "Step 4: Uploading HTML files to S3..."
if [ -f "$PROJECT_ROOT/html/index.html" ]; then
  aws s3 cp "$PROJECT_ROOT/html/index.html" "s3://$S3_BUCKET/"
else
  print_warning "index.html not found, skipping upload."
fi
if [ -f "$PROJECT_ROOT/html/error.html" ]; then
  aws s3 cp "$PROJECT_ROOT/html/error.html" "s3://$S3_BUCKET/"
else
  print_warning "error.html not found, skipping upload."
fi
print_success "HTML files uploaded to S3 (if present) ✓"

cd "$PROJECT_ROOT"

print_success "Deployment Complete! 🎉"
echo ""
print_status "📋 Infrastructure Summary:"
print_status "  API Gateway URL: $API_URL"
print_status "  S3 Bucket: $S3_BUCKET"
echo ""
print_status "🧪 To test the deployment, run: ./scripts/test.sh"
print_status "🗑️  To destroy all resources, run: ./scripts/destroy.sh" 