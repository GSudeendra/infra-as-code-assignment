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

echo "🚀 Starting Infrastructure Deployment"
echo "====================================="

# Resolve project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Check AWS CLI configuration
print_status "Checking AWS CLI configuration..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    print_success "AWS CLI configured ✓"
else
    print_error "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Hardcode the Terraform execution role name
TERRAFORM_EXECUTION_ROLE_NAME="github-actions-oidc-role"

# Step 1: Deploy Remote State Infrastructure
print_status "Step 1: Deploying Remote State Infrastructure..."
cd "$PROJECT_ROOT/infra/backend"

print_status "Cleaning previous Terraform state (CI/CD best practice)..."
rm -rf .terraform .terraform.lock.hcl

print_status "Initializing Terraform (remote state)..."
terraform init -upgrade

print_status "Using Terraform execution role: ${TERRAFORM_EXECUTION_ROLE_NAME}"

print_status "Planning remote state infrastructure..."
terraform plan \
  -var="terraform_execution_role_name=${TERRAFORM_EXECUTION_ROLE_NAME}" \
  -out=tfplan

print_status "Applying remote state infrastructure..."
terraform apply -auto-approve tfplan

# Get outputs
S3_BUCKET=$(terraform output -raw s3_bucket_name)
DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)

print_success "Remote state infrastructure deployed ✓"
print_status "State bucket: $S3_BUCKET"
print_status "Lock table: $DYNAMODB_TABLE"

cd "$PROJECT_ROOT"

# Step 2: Update Backend Configuration
print_status "Step 2: Updating Backend Configuration..."
cd "$PROJECT_ROOT/infra"

cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "$S3_BUCKET"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF

print_success "Backend configuration updated ✓"

# Step 3: Build Lambda ZIPs
print_status "Step 3: Building Lambda ZIPs..."
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

# Step 4: Deploy Main Infrastructure
print_status "Step 4: Deploying Main Infrastructure..."

print_status "Initializing Terraform..."
terraform init

print_status "Planning main infrastructure..."
terraform plan -out=tfplan

print_status "Applying main infrastructure..."
terraform apply -auto-approve tfplan

# Get API Gateway URL
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")

print_success "Main infrastructure deployed ✓"

# Step 5: Upload HTML files to S3
print_status "Step 5: Uploading HTML files to S3..."
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