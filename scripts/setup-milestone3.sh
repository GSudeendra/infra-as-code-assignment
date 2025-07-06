#!/bin/bash

# Milestone 3 Setup Script
# This script helps set up the CI/CD infrastructure for Milestone 3

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Function to get user input
get_user_input() {
    print_status "Please provide the following information:"
    
    read -p "Enter your GitHub username: " GITHUB_USERNAME
    read -p "Enter your GitHub repository name: " GITHUB_REPO_NAME
    read -p "Enter environment name (default: dev): " ENVIRONMENT
    ENVIRONMENT=${ENVIRONMENT:-dev}
    
    print_success "Configuration saved!"
}

# Function to update GitHub OIDC configuration
update_oidc_config() {
    print_status "Updating GitHub OIDC configuration..."
    
    # Create backup of original file
    cp remote-state/github-oidc.tf remote-state/github-oidc.tf.backup
    
    # Update the repository reference
    sed -i.bak "s|repo:sudeendrag/infra-as-code-assignment|repo:${GITHUB_USERNAME}/${GITHUB_REPO_NAME}|g" remote-state/github-oidc.tf
    
    print_success "GitHub OIDC configuration updated!"
}

# Function to update environment variable
update_environment() {
    print_status "Updating environment configuration..."
    
    # Create backup of original file
    cp remote-state/variables.tf remote-state/variables.tf.backup
    
    # Update environment variable
    sed -i.bak "s|default     = \"dev\"|default     = \"${ENVIRONMENT}\"|g" remote-state/variables.tf
    
    print_success "Environment configuration updated!"
}

# Function to deploy remote state infrastructure
deploy_remote_state() {
    print_status "Deploying remote state infrastructure..."
    
    cd remote-state
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan
    
    # Ask for confirmation
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply -auto-approve
        
        # Get outputs
        S3_BUCKET_NAME=$(terraform output -raw s3_bucket_name)
        DYNAMODB_TABLE_NAME=$(terraform output -raw dynamodb_table_name)
        GITHUB_ROLE_ARN=$(terraform output -raw github_actions_role_arn)
        
        print_success "Remote state infrastructure deployed successfully!"
        print_status "S3 Bucket: $S3_BUCKET_NAME"
        print_status "DynamoDB Table: $DYNAMODB_TABLE_NAME"
        print_status "GitHub Actions Role ARN: $GITHUB_ROLE_ARN"
        
        # Save outputs to file
        cat > ../terraform-setup-outputs.txt << EOF
# Terraform Setup Outputs
# Save these values for later use

S3_BUCKET_NAME=$S3_BUCKET_NAME
DYNAMODB_TABLE_NAME=$DYNAMODB_TABLE_NAME
GITHUB_ACTIONS_ROLE_ARN=$GITHUB_ROLE_ARN

# Instructions:
# 1. Add GITHUB_ACTIONS_ROLE_ARN as AWS_ROLE_ARN secret in your GitHub repository
# 2. Update terraform/backend.tf with S3_BUCKET_NAME and DYNAMODB_TABLE_NAME
# 3. Run: cd terraform && terraform init
EOF
        
        print_success "Outputs saved to terraform-setup-outputs.txt"
    else
        print_warning "Deployment cancelled."
        exit 1
    fi
    
    cd ..
}

# Function to update backend configuration
update_backend_config() {
    print_status "Updating backend configuration..."
    
    # Create backup of original file
    cp terraform/backend.tf terraform/backend.tf.backup
    
    # Update backend configuration
    cat > terraform/backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "$S3_BUCKET_NAME"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "$DYNAMODB_TABLE_NAME"
    encrypt        = true
  }
}
EOF
    
    print_success "Backend configuration updated!"
}

# Function to initialize main Terraform project
init_main_terraform() {
    print_status "Initializing main Terraform project..."
    
    cd terraform
    
    # Initialize with new backend
    terraform init
    
    print_success "Main Terraform project initialized!"
    cd ..
}

# Function to display next steps
display_next_steps() {
    print_success "Setup completed successfully!"
    echo
    print_status "Next steps:"
    echo "1. Add the GitHub Actions role ARN as a repository secret:"
    echo "   - Go to your GitHub repository → Settings → Secrets and Variables → Actions"
    echo "   - Add secret: AWS_ROLE_ARN = $GITHUB_ROLE_ARN"
    echo
    echo "2. Push your changes to trigger the CI/CD pipeline:"
    echo "   git add ."
    echo "   git commit -m 'Setup Milestone 3 CI/CD infrastructure'"
    echo "   git push origin main"
    echo
    echo "3. Monitor the deployment:"
    echo "   - Go to Actions tab in your GitHub repository"
    echo "   - Watch the 'Deploy Infrastructure' workflow"
    echo
    echo "4. Test the application:"
    echo "   - Run: cd tests && pip install -r requirements.txt && python -m pytest -v"
    echo
    print_warning "Important: Make sure to add the AWS_ROLE_ARN secret to your GitHub repository before pushing!"
}

# Main execution
main() {
    echo "=========================================="
    echo "    Milestone 3 Setup Script"
    echo "=========================================="
    echo
    
    check_prerequisites
    get_user_input
    update_oidc_config
    update_environment
    deploy_remote_state
    update_backend_config
    init_main_terraform
    display_next_steps
}

# Run main function
main "$@" 