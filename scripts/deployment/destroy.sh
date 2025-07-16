#!/bin/bash

set -e

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

echo "🗑️  Starting Infrastructure Destroy"
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

TERRAFORM_EXECUTION_ROLE_NAME="github-actions-oidc-role"

print_status "Step 1: Destroying Main Infrastructure..."
cd "$PROJECT_ROOT/infra"

print_status "Initializing Terraform..."
terraform init

print_status "Destroying main infrastructure..."
terraform destroy -auto-approve

print_success "Main infrastructure destroyed ✓"

print_status "Step 2: Destroying Remote State Infrastructure..."
cd "$PROJECT_ROOT/infra/backend"

print_status "Cleaning previous Terraform state (CI/CD best practice)..."
rm -rf .terraform .terraform.lock.hcl

print_status "Initializing Terraform (remote state)..."
terraform init -upgrade

print_status "Destroying remote state infrastructure..."
terraform destroy \
  -var="terraform_execution_role_name=${TERRAFORM_EXECUTION_ROLE_NAME}" \
  -auto-approve

print_success "Remote state infrastructure destroyed ✓"

cd "$PROJECT_ROOT"

print_success "Destroy Complete! 🎉" 