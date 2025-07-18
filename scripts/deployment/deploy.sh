#!/bin/bash

set -e

PROJECT_NAME="iac-user-management"
ENVIRONMENT="dev"
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

# Removed admin bootstrap section

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