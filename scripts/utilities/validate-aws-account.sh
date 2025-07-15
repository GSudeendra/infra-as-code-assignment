#!/bin/bash

# AWS Account Validation Script
# Validates AWS credentials and account configuration

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

echo "🔍 AWS Account Validation"
echo "========================="

# Expected AWS Beach account ID
EXPECTED_ACCOUNT_ID="160071257600"
EXPECTED_PROFILE="twbeach"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

print_success "AWS CLI is installed ✓"

# Check if AWS credentials are configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    print_error "AWS credentials not configured. Please run 'aws configure' or 'aws sso login' first."
    exit 1
fi

print_success "AWS credentials are configured ✓"

# Get current account ID
CURRENT_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
CURRENT_USER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)

print_status "Current Account ID: $CURRENT_ACCOUNT_ID"
print_status "Current User ARN: $CURRENT_USER_ARN"

# Validate account ID
if [ "$CURRENT_ACCOUNT_ID" = "$EXPECTED_ACCOUNT_ID" ]; then
    print_success "✅ Correct AWS account (Beach account #$EXPECTED_ACCOUNT_ID) ✓"
else
    print_error "❌ Wrong AWS account! Expected: $EXPECTED_ACCOUNT_ID, Got: $CURRENT_ACCOUNT_ID"
    print_warning "Please switch to the correct AWS account before proceeding."
    exit 1
fi

# Check if using the expected profile
if [ "$AWS_PROFILE" = "$EXPECTED_PROFILE" ]; then
    print_success "✅ Using expected AWS profile ($EXPECTED_PROFILE) ✓"
elif [ -n "$AWS_PROFILE" ]; then
    print_warning "⚠️  Using AWS profile: $AWS_PROFILE (expected: $EXPECTED_PROFILE)"
else
    print_warning "⚠️  No AWS profile set (expected: $EXPECTED_PROFILE)"
fi

# Test basic permissions
print_status "Testing AWS permissions..."

# Test S3 permissions
if aws s3 ls > /dev/null 2>&1; then
    print_success "✅ S3 permissions: OK"
else
    print_warning "⚠️  S3 permissions: Limited or missing"
fi

# Test DynamoDB permissions
if aws dynamodb list-tables > /dev/null 2>&1; then
    print_success "✅ DynamoDB permissions: OK"
else
    print_warning "⚠️  DynamoDB permissions: Limited or missing"
fi

# Test Lambda permissions
if aws lambda list-functions > /dev/null 2>&1; then
    print_success "✅ Lambda permissions: OK"
else
    print_warning "⚠️  Lambda permissions: Limited or missing"
fi

# Test IAM permissions
if aws iam get-user > /dev/null 2>&1; then
    print_success "✅ IAM permissions: OK"
else
    print_warning "⚠️  IAM permissions: Limited or missing"
fi

echo ""
print_success "🎉 AWS account validation completed successfully!"
print_status "You can now proceed with infra operations." 