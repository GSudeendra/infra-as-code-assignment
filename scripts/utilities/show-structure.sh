#!/bin/bash

# Project Structure Display Script
# Shows the organized project layout

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

print_dir() {
    echo -e "${BLUE}$1${NC}"
}

print_file() {
    echo -e "${GREEN}$1${NC}"
}

print_script() {
    echo -e "${YELLOW}$1${NC}"
}

print_terraform() {
    echo -e "${CYAN}$1${NC}"
}

echo "📁 Infrastructure as Code Assignment - Project Structure"
echo "========================================================"

# Function to show directory structure
show_structure() {
    echo ""
    print_header "🏗️  Infrastructure Components"
    echo "├── terraform/"
    echo "│   ├── main.tf"
    echo "│   ├── variables.tf"
    echo "│   ├── outputs.tf"
    echo "│   └── backend.tf"
    echo ""
    echo "├── remote-state/"
    echo "│   ├── main.tf"
    echo "│   ├── variables.tf"
    echo "│   └── outputs.tf"
    echo ""
    echo "├── modules/"
    echo "│   ├── lambda/"
    echo "│   │   ├── main.tf"
    echo "│   │   ├── variables.tf"
    echo "│   │   └── outputs.tf"
    echo "│   ├── api-gateway/"
    echo "│   │   ├── main.tf"
    echo "│   │   ├── variables.tf"
    echo "│   │   └── outputs.tf"
    echo "│   ├── dynamodb/"
    echo "│   │   ├── main.tf"
    echo "│   │   ├── variables.tf"
    echo "│   │   └── outputs.tf"
    echo "│   └── s3/"
    echo "│       ├── main.tf"
    echo "│       ├── variables.tf"
    echo "│       └── outputs.tf"
    
    echo ""
    print_header "💻 Application Code"
    echo "├── src/"
    echo "│   ├── lambda/"
    echo "│   │   ├── register_user.py"
    echo "│   │   ├── verify_user.py"
    echo "│   │   └── requirements.txt"
    echo "│   └── html/"
    echo "│       ├── index.html"
    echo "│       └── error.html"
    
    echo ""
    print_header "🧪 Testing"
    echo "├── tests/"
    echo "│   ├── test_user_management_api.py"
    echo "│   ├── conftest.py"
    echo "│   └── requirements.txt"
    
    echo ""
    print_header "🚀 Automation Scripts"
    echo "├── scripts/"
    echo "│   ├── deployment/"
    echo "│   │   ├── deploy.sh"
    echo "│   │   └── destroy.sh"
    echo "│   ├── testing/"
    echo "│   │   └── test.sh"
    echo "│   ├── utilities/"
    echo "│   │   ├── validate-aws-account.sh"
    echo "│   │   ├── build-lambdas.sh"
    echo "│   │   ├── import-log-groups.sh"
    echo "│   │   └── show-structure.sh"
    echo "│   ├── pre-terraform-hook.sh"
    echo "│   └── README.md"
    
    echo ""
    print_header "📋 Configuration Files"
    echo "├── .gitignore"
    echo "├── env.example"
    echo "├── aws-config-template.txt"
    echo "└── README.md"
}

# Function to show quick commands
show_commands() {
    echo ""
    print_header "⚡ Quick Commands"
    echo ""
    echo "🚀 Deploy everything:"
    echo "   ./scripts/deployment/deploy.sh"
    echo ""
    echo "🧪 Test the deployment:"
    echo "   ./scripts/testing/test.sh"
    echo ""
    echo "🗑️  Destroy everything:"
    echo "   ./scripts/deployment/destroy.sh"
    echo ""
    echo "🔨 Build Lambda packages:"
    echo "   ./scripts/utilities/build-lambdas.sh"
    echo ""
    echo "🔍 Validate AWS account:"
    echo "   ./scripts/utilities/validate-aws-account.sh"
    echo ""
    echo "📊 Manage CloudWatch logs:"
    echo "   ./scripts/utilities/import-log-groups.sh"
}

# Function to show project info
show_info() {
    echo ""
    print_header "ℹ️  Project Information"
    echo ""
    echo "📝 Description: Infrastructure as Code assignment implementing"
    echo "   a serverless user management system with AWS services"
    echo ""
    echo "🎯 Milestone: 2 (Complete implementation)"
    echo ""
    echo "🏗️  Architecture:"
    echo "   • API Gateway (HTTP API)"
    echo "   • Lambda Functions (register_user, verify_user)"
    echo "   • DynamoDB (User storage)"
    echo "   • S3 (Static content hosting)"
    echo "   • CloudWatch (Logging)"
    echo "   • IAM (Security)"
    echo ""
    echo "🔧 Technologies:"
    echo "   • Terraform (Infrastructure as Code)"
    echo "   • Python (Lambda functions)"
    echo "   • AWS Services (Various)"
    echo "   • Pytest (Testing)"
    echo ""
    echo "📁 Organization:"
    echo "   • Modular Terraform structure"
    echo "   • Organized scripts by purpose"
    echo "   • Clear separation of concerns"
    echo "   • Comprehensive documentation"
}

# Main menu
show_menu() {
    echo ""
    print_header "Choose an option:"
    echo "1. Show project structure"
    echo "2. Show quick commands"
    echo "3. Show project information"
    echo "4. Show everything"
    echo "5. Exit"
    echo ""
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1)
            show_structure
            ;;
        2)
            show_commands
            ;;
        3)
            show_info
            ;;
        4)
            show_structure
            show_commands
            show_info
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please try again."
            ;;
    esac
}

# Check if running interactively
if [ -t 0 ]; then
    # Interactive mode
    while true; do
        show_menu
    done
else
    # Non-interactive mode - show everything
    show_structure
    show_commands
    show_info
fi 