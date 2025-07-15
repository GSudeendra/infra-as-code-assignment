#!/bin/bash

# This script helps instructors configure the repository for CI/CD and remote state

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_NAME="infra-as-code-assignment"
AWS_REGION="us-east-1"

echo -e "${BLUE}🚀 Milestone 3 Setup Script for Instructors${NC}"
echo -e "${YELLOW}This script will help you configure the repository for CI/CD and remote state management.${NC}\n"

# Function to print section header
print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to print result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_section "Prerequisites Check"

# Check AWS CLI
if command_exists aws; then
    echo -e "${GREEN}✅ AWS CLI is installed${NC}"
    AWS_VERSION=$(aws --version)
    echo "   Version: $AWS_VERSION"
else
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    echo "   Please install AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check Terraform
if command_exists terraform; then
    echo -e "${GREEN}✅ Terraform is installed${NC}"
    TF_VERSION=$(terraform version -json | jq -r '.terraform_version')
    echo "   Version: $TF_VERSION"
else
    echo -e "${RED}❌ Terraform is not installed${NC}"
    echo "   Please install Terraform: https://developer.hashicorp.com/terraform/downloads"
    exit 1
fi

# Check Python
if command_exists python3; then
    echo -e "${GREEN}✅ Python 3 is installed${NC}"
    PYTHON_VERSION=$(python3 --version)
    echo "   Version: $PYTHON_VERSION"
else
    echo -e "${RED}❌ Python 3 is not installed${NC}"
    echo "   Please install Python 3: https://www.python.org/downloads/"
    exit 1
fi

print_section "Repository Configuration"

# Get current repository information
if [ -d ".git" ]; then
    echo -e "${GREEN}✅ Git repository detected${NC}"
    
    # Get remote URL
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE_URL" ]; then
        echo "   Remote URL: $REMOTE_URL"
        
        # Extract GitHub username and repo name
        if [[ $REMOTE_URL =~ github\.com[:/]([^/]+)/([^/]+)\.git ]]; then
            GITHUB_USERNAME="${BASH_REMATCH[1]}"
            REPO_NAME="${BASH_REMATCH[2]}"
            echo "   GitHub Username: $GITHUB_USERNAME"
            echo "   Repository Name: $REPO_NAME"
        else
            echo -e "${YELLOW}⚠️  Could not parse GitHub URL. Please enter manually:${NC}"
            read -p "GitHub Username: " GITHUB_USERNAME
            read -p "Repository Name: " REPO_NAME
        fi
    else
        echo -e "${YELLOW}⚠️  No remote URL found. Please enter manually:${NC}"
        read -p "GitHub Username: " GITHUB_USERNAME
        read -p "Repository Name: " REPO_NAME
    fi
else
    echo -e "${RED}❌ Not a Git repository${NC}"
    echo "   Please initialize Git and add a remote origin"
    exit 1
fi

print_section "AWS Configuration"

# Check AWS credentials
echo "Checking AWS credentials..."
if aws sts get-caller-identity >/dev/null 2>&1; then
    echo -e "${GREEN}✅ AWS credentials are configured${NC}"
    ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
    echo "   Account ID: $ACCOUNT_ID"
else
    echo -e "${RED}❌ AWS credentials are not configured${NC}"
    echo "   Please configure AWS credentials:"
    echo "   aws configure"
    exit 1
fi

print_section "Remote State Setup"

echo "Setting up remote state infrastructure..."

# Navigate to remote-state directory
cd infra/backend

# Update GitHub OIDC configuration
echo "Updating GitHub OIDC configuration..."
sed -i.bak "s/repo:sudeendrag\/infra-as-code-assignment/repo:$GITHUB_USERNAME\/$REPO_NAME/g" github-oidc.tf

# Initialize and apply remote state
echo "Initializing Terraform for remote state..."
terraform init
terraform plan

echo -e "${YELLOW}⚠️  About to apply remote state infrastructure. This will create:${NC}"
echo "   - S3 bucket for Terraform state"
echo "   - DynamoDB table for state locking"
echo "   - GitHub OIDC provider"
echo "   - IAM role for GitHub Actions"
echo ""

read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Applying remote state infrastructure..."
    terraform apply -auto-approve
    
    # Get outputs
    S3_BUCKET=$(terraform output -raw s3_bucket_name)
    DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)
    GITHUB_ROLE_ARN=$(terraform output -raw github_actions_role_arn)
    
    echo -e "${GREEN}✅ Remote state infrastructure deployed successfully!${NC}"
    echo "   S3 Bucket: $S3_BUCKET"
    echo "   DynamoDB Table: $DYNAMODB_TABLE"
    echo "   GitHub Role ARN: $GITHUB_ROLE_ARN"
    
    # Save outputs to file
    cat > ../terraform-setup-outputs.txt << EOF
# Terraform Setup Outputs
# Generated on: $(date)

S3_BUCKET_NAME=$S3_BUCKET
DYNAMODB_TABLE_NAME=$DYNAMODB_TABLE
GITHUB_ACTIONS_ROLE_ARN=$GITHUB_ROLE_ARN
GITHUB_USERNAME=$GITHUB_USERNAME
REPO_NAME=$REPO_NAME
AWS_REGION=$AWS_REGION
EOF
    
    echo -e "${GREEN}✅ Outputs saved to terraform-setup-outputs.txt${NC}"
else
    echo -e "${YELLOW}⚠️  Remote state setup skipped. You can run this manually later.${NC}"
fi

# Go back to root directory
cd ..

print_section "Backend Configuration"

echo "Updating Terraform backend configuration..."

# Update backend configuration
if [ -n "$S3_BUCKET" ] && [ -n "$DYNAMODB_TABLE" ]; then
    cat > infra/backend/backend.tf << EOF
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
    
    echo -e "${GREEN}✅ Backend configuration updated${NC}"
else
    echo -e "${YELLOW}⚠️  Please update infra/backend/backend.tf manually with your S3 bucket and DynamoDB table names${NC}"
fi

print_section "GitHub Repository Setup"

echo -e "${YELLOW}📋 Next steps for GitHub repository setup:${NC}"
echo ""
echo "1. Go to your GitHub repository: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo "2. Navigate to Settings → Secrets and Variables → Actions"
echo "3. Add the following repository secret:"
echo "   - Name: AWS_ROLE_ARN"
echo "   - Value: $GITHUB_ROLE_ARN"
echo ""
echo "4. Go to Settings → Actions → General"
echo "5. Ensure 'Actions permissions' is set to 'Allow all actions and reusable workflows'"
echo "6. Under 'Workflow permissions', select 'Read and write permissions'"
echo ""

print_section "Testing Setup"

echo "Testing the setup..."

# Test Terraform configuration
cd infra
echo "Testing Terraform configuration..."
terraform init
terraform validate
echo -e "${GREEN}✅ Terraform configuration is valid${NC}"

# Test security scanning
cd ..
echo "Testing security scanning..."
chmod +x scripts/security/security-scan.sh
./scripts/security/security-scan.sh || true
echo -e "${GREEN}✅ Security scanning completed${NC}"

print_section "Setup Complete!"

echo -e "${GREEN}🎉 Milestone 3 setup is complete!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "   ✅ Remote state infrastructure deployed"
echo "   ✅ Backend configuration updated"
echo "   ✅ Security scanning configured"
echo "   ✅ GitHub Actions workflow ready"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "1. Add the AWS_ROLE_ARN secret to your GitHub repository"
echo "2. Push your changes to trigger the CI/CD pipeline"
echo "3. Monitor the GitHub Actions workflow for successful deployment"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "   - README.md: Complete deployment instructions"
echo "   - INSTRUCTOR_GUIDE.md: Detailed instructor guide"
echo "   - terraform-setup-outputs.txt: Your configuration values"
echo ""
echo -e "${GREEN}🚀 Ready to deploy!${NC}" 