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

# Check AWS CLI configuration
print_status "Checking AWS CLI configuration..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    print_success "AWS CLI configured ✓"
else
    print_error "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Step 1: Deploy Remote State Infrastructure
print_status "Step 1: Deploying Remote State Infrastructure..."
cd remote-state

print_status "Planning remote state infrastructure..."
terraform plan -out=tfplan

print_status "Applying remote state infrastructure..."
terraform apply tfplan

# Get outputs
S3_BUCKET=$(terraform output -raw s3_bucket_name)
DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)

print_success "Remote state infrastructure deployed ✓"
print_status "State bucket: $S3_BUCKET"
print_status "Lock table: $DYNAMODB_TABLE"

cd ..

# Step 2: Update Backend Configuration
print_status "Step 2: Updating Backend Configuration..."
cd terraform

# Update backend configuration
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
cd ../modules/lambda

# Create ZIP files for Lambda functions
echo "Building register_user from ../src/lambda/register_user.py → register_user.zip"
zip -j register_user.zip ../src/lambda/register_user.py

echo "Building verify_user from ../src/lambda/verify_user.py → verify_user.zip"
zip -j verify_user.zip ../src/lambda/verify_user.py

print_success "Lambda ZIPs built ✓"

cd ../../terraform

# Step 4: Deploy Main Infrastructure
print_status "Step 4: Deploying Main Infrastructure..."

print_status "Initializing Terraform..."
terraform init

print_status "Planning main infrastructure..."
terraform plan -out=tfplan

print_status "Applying main infrastructure..."
terraform apply tfplan

# Get API Gateway URL
API_URL=$(terraform output -raw api_gateway_url)

print_success "Main infrastructure deployed ✓"

cd ..

print_success "Deployment Complete! 🎉"
echo ""
print_status "📋 Infrastructure Summary:"
print_status "  API Gateway URL: $API_URL"
print_status "  S3 Bucket ARN: $(cd terraform && terraform output -raw s3_bucket_arn)"
echo ""
print_status "🧪 To test the deployment, run: ./scripts/test.sh"
print_status "🗑️  To destroy all resources, run: ./scripts/destroy.sh" 