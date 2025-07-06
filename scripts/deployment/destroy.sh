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

echo "🗑️  Starting Infrastructure Destruction"
echo "======================================"

# Check AWS CLI configuration
print_status "Checking AWS CLI configuration..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    print_success "AWS CLI configured ✓"
else
    print_error "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Step 1: Destroy Main Infrastructure
print_status "Step 1: Destroying Main Infrastructure..."
cd terraform

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    print_status "Initializing Terraform..."
    terraform init
fi

print_status "Destroying main infrastructure..."
terraform destroy -auto-approve

print_success "Main infrastructure destroyed ✓"
cd ..

# Step 2: Destroy Remote State Infrastructure
print_status "Step 2: Destroying Remote State Infrastructure..."
cd remote-state

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    print_status "Initializing Terraform..."
    terraform init
fi

print_status "Destroying remote state infrastructure..."
terraform destroy -auto-approve

print_success "Remote state infrastructure destroyed ✓"
cd ..

print_success "Destruction Complete! 🎉"
echo ""
print_status "📋 Cleanup Summary:"
print_status "  - Main infrastructure: Destroyed"
print_status "  - Remote state infrastructure: Destroyed"
print_status "  - All AWS resources: Removed"
echo ""
print_status "🚀 To redeploy, run: ./scripts/deploy.sh" 