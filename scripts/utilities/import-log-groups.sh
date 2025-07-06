#!/bin/bash

# CloudWatch Log Group Import Script
# Helps with importing existing CloudWatch log groups into Terraform state

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

echo "📊 CloudWatch Log Group Management"
echo "=================================="

# Check AWS CLI configuration
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    print_error "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Function to list existing log groups
list_log_groups() {
    print_status "Listing existing CloudWatch log groups..."
    
    # Get log groups that might be related to our Lambda functions
    LOG_GROUPS=$(aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, `lambda`) || contains(logGroupName, `register_user`) || contains(logGroupName, `verify_user`)].logGroupName' --output text)
    
    if [ -z "$LOG_GROUPS" ]; then
        print_warning "No relevant log groups found."
        return
    fi
    
    echo ""
    print_status "Found log groups:"
    for group in $LOG_GROUPS; do
        echo "  - $group"
    done
}

# Function to generate import commands
generate_import_commands() {
    print_status "Generating Terraform import commands..."
    
    # Get log groups
    LOG_GROUPS=$(aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, `lambda`) || contains(logGroupName, `register_user`) || contains(logGroupName, `verify_user`)].logGroupName' --output text)
    
    if [ -z "$LOG_GROUPS" ]; then
        print_warning "No log groups to import."
        return
    fi
    
    echo ""
    print_status "Terraform import commands:"
    echo ""
    
    for group in $LOG_GROUPS; do
        # Extract function name from log group name
        FUNCTION_NAME=$(echo "$group" | sed 's|/aws/lambda/||' | sed 's|-.*||')
        
        echo "# Import log group for $FUNCTION_NAME"
        echo "terraform import aws_cloudwatch_log_group.${FUNCTION_NAME}_logs '$group'"
        echo ""
    done
}

# Function to delete log groups
delete_log_groups() {
    print_warning "⚠️  This will delete CloudWatch log groups. Are you sure? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_status "Deleting log groups..."
        
        LOG_GROUPS=$(aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, `lambda`) || contains(logGroupName, `register_user`) || contains(logGroupName, `verify_user`)].logGroupName' --output text)
        
        for group in $LOG_GROUPS; do
            print_status "Deleting: $group"
            aws logs delete-log-group --log-group-name "$group" 2>/dev/null || print_warning "Failed to delete $group"
        done
        
        print_success "Log groups deleted."
    else
        print_status "Operation cancelled."
    fi
}

# Main menu
show_menu() {
    echo ""
    print_status "Choose an option:"
    echo "1. List existing log groups"
    echo "2. Generate Terraform import commands"
    echo "3. Delete log groups (⚠️  destructive)"
    echo "4. Exit"
    echo ""
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            list_log_groups
            ;;
        2)
            generate_import_commands
            ;;
        3)
            delete_log_groups
            ;;
        4)
            print_status "Exiting..."
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
    # Non-interactive mode - just list and generate commands
    list_log_groups
    generate_import_commands
fi 