#!/bin/bash

# Lambda Build Script
# Creates ZIP files from Lambda source code

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

echo "🔨 Lambda Build Script"
echo "======================"

# Define paths
LAMBDA_SRC_DIR="src/lambda"
LAMBDA_BUILD_DIR="infra/modules/lambda"
PROJECT_ROOT=$(pwd)

# Check if we're in the project root
if [ ! -d "$LAMBDA_SRC_DIR" ]; then
    print_error "Lambda source directory not found: $LAMBDA_SRC_DIR"
    print_error "Please run this script from the project root directory."
    exit 1
fi

# Create build directory if it doesn't exist
if [ ! -d "$LAMBDA_BUILD_DIR" ]; then
    print_status "Creating Lambda build directory: $LAMBDA_BUILD_DIR"
    mkdir -p "$LAMBDA_BUILD_DIR"
fi

# Function to build a Lambda function
build_lambda() {
    local function_name=$1
    local source_file="$LAMBDA_SRC_DIR/${function_name}.py"
    local requirements_file="$LAMBDA_SRC_DIR/requirements.txt"
    local zip_file="$LAMBDA_BUILD_DIR/${function_name}.zip"
    
    print_status "Building $function_name..."
    
    # Check if source file exists
    if [ ! -f "$PROJECT_ROOT/$source_file" ]; then
        print_error "Source file not found: $PROJECT_ROOT/$source_file"
        return 1
    fi
    
    # Create temporary build directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Copy source file
    cp "$PROJECT_ROOT/$source_file" .
    
    # Copy requirements and install dependencies if they exist
    if [ -f "$PROJECT_ROOT/$requirements_file" ]; then
        print_status "Installing dependencies for $function_name..."
        cp "$PROJECT_ROOT/$requirements_file" .
        pip install -r requirements.txt -t . --quiet
    fi
    
    # Create ZIP file
    print_status "Creating ZIP file: $zip_file"
    zip -r "$PROJECT_ROOT/$zip_file" . -q
    
    # Clean up
    cd "$PROJECT_ROOT"
    rm -rf "$temp_dir"
    
    # Check if ZIP was created successfully
    if [ -f "$PROJECT_ROOT/$zip_file" ]; then
        local zip_size=$(du -h "$PROJECT_ROOT/$zip_file" | cut -f1)
        print_success "✅ $function_name built successfully ($zip_size)"
    else
        print_error "❌ Failed to create ZIP file for $function_name"
        return 1
    fi
}

# Build all Lambda functions
print_status "Building Lambda functions..."

# List of Lambda functions to build
LAMBDA_FUNCTIONS=("register_user" "verify_user")

for function in "${LAMBDA_FUNCTIONS[@]}"; do
    if ! build_lambda "$function"; then
        print_error "Failed to build $function"
        exit 1
    fi
done

echo ""
print_success "🎉 All Lambda functions built successfully!"
print_status "ZIP files created in: $LAMBDA_BUILD_DIR"

# List created files
echo ""
print_status "📋 Created files:"
ls -la "$LAMBDA_BUILD_DIR"/*.zip 2>/dev/null || print_warning "No ZIP files found"

echo ""
print_status "🚀 Ready for deployment!"
print_status "Run './scripts/deployment/deploy.sh' to deploy the infrastructure." 