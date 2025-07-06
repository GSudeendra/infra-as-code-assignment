#!/bin/bash

# Pre-Terraform Hook Script
# This script validates AWS account before any Terraform operation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Expected AWS Beach account ID
EXPECTED_ACCOUNT_ID="160071257600"
EXPECTED_PROFILE="twbeach"

echo "🔍 Pre-Terraform AWS Account Validation..."

# Check if we're in a Terraform directory
if [[ "$PWD" == *"terraform"* ]] || [[ -f "main.tf" ]] || [[ -f "*.tf" ]]; then
    print_status "Terraform operation detected, validating AWS account..."
    
    # Validate AWS account
    source "$(dirname "$0")/validate-aws-account.sh"
    
    print_status "✅ AWS account validation passed. Proceeding with Terraform operation."
else
    print_status "Not in Terraform context, skipping AWS validation."
fi 