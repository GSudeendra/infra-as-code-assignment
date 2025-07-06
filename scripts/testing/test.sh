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

echo "🧪 Starting Comprehensive API Testing"
echo "====================================="

# Check if infrastructure is deployed
print_status "Checking if infrastructure is deployed..."

if [ ! -f "terraform/terraform.tfstate" ]; then
    print_error "No Terraform state found. Please deploy infrastructure first with './scripts/deploy.sh'"
    exit 1
fi

# Get API Gateway URL from Terraform state
print_status "Getting API Gateway URL from Terraform state..."
cd terraform

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    print_status "Initializing Terraform..."
    terraform init
fi

# Get the API Gateway URL
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")

if [ -z "$API_URL" ]; then
    print_error "Could not get API Gateway URL from Terraform state."
    print_error "Please ensure infrastructure is deployed and API Gateway is created."
    exit 1
fi

print_success "API Gateway URL: $API_URL"
cd ..

# Set environment variable for tests
export API_GATEWAY_URL="$API_URL"
print_status "Set API_GATEWAY_URL environment variable: $API_GATEWAY_URL"

echo ""
print_status "Step 1: Running Automated Python Tests"
echo "---------------------------------------------"

# Check if Python virtual environment exists
if [ ! -d ".venv" ]; then
    print_status "Creating Python virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source .venv/bin/activate

# Install test dependencies
print_status "Installing test dependencies..."
cd tests
pip install -r requirements.txt

# Run Python tests
print_status "Running Python tests..."
pytest test_user_management_api.py -v

cd ..

echo ""
print_status "Step 2: Running Curl-based API Tests"
echo "-------------------------------------------"

# Test data
TEST_USER_ID="testuser_$(date +%s)"

print_status "Testing with user ID: $TEST_USER_ID"

# Test 1: Register user (should succeed)
print_status "Test 1: Registering user..."
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/register?userId=$TEST_USER_ID")
REGISTER_HTTP_CODE=$(echo "$REGISTER_RESPONSE" | tail -n1)
REGISTER_BODY=$(echo "$REGISTER_RESPONSE" | sed '$d')

if [ "$REGISTER_HTTP_CODE" = "200" ]; then
    print_success "✅ User registration successful (HTTP $REGISTER_HTTP_CODE)"
    echo "Response: $REGISTER_BODY"
else
    print_error "❌ User registration failed (HTTP $REGISTER_HTTP_CODE)"
    echo "Response: $REGISTER_BODY"
fi

# Test 2: Register same user again (should return "already registered")
print_status "Test 2: Attempting to register same user (idempotency test)..."
REGISTER_DUPLICATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/register?userId=$TEST_USER_ID")
REGISTER_DUPLICATE_HTTP_CODE=$(echo "$REGISTER_DUPLICATE_RESPONSE" | tail -n1)
REGISTER_DUPLICATE_BODY=$(echo "$REGISTER_DUPLICATE_RESPONSE" | sed '$d')

if [ "$REGISTER_DUPLICATE_HTTP_CODE" = "200" ]; then
    print_success "✅ Duplicate registration handled correctly (HTTP $REGISTER_DUPLICATE_HTTP_CODE)"
    echo "Response: $REGISTER_DUPLICATE_BODY"
else
    print_warning "⚠️  Duplicate registration returned unexpected status (HTTP $REGISTER_DUPLICATE_HTTP_CODE)"
    echo "Response: $REGISTER_DUPLICATE_BODY"
fi

# Test 3: Verify user (should succeed)
print_status "Test 3: Verifying user..."
VERIFY_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/verify?userId=$TEST_USER_ID")
VERIFY_HTTP_CODE=$(echo "$VERIFY_RESPONSE" | tail -n1)
VERIFY_BODY=$(echo "$VERIFY_RESPONSE" | sed '$d')

if [ "$VERIFY_HTTP_CODE" = "200" ]; then
    print_success "✅ User verification successful (HTTP $VERIFY_HTTP_CODE)"
    echo "Response: $VERIFY_BODY"
else
    print_error "❌ User verification failed (HTTP $VERIFY_HTTP_CODE)"
    echo "Response: $VERIFY_BODY"
fi

# Test 4: Verify non-existent user (should fail)
print_status "Test 4: Verifying non-existent user..."
NONEXISTENT_USER_ID="nonexistent_$(date +%s)"
VERIFY_NONEXISTENT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/verify?userId=$NONEXISTENT_USER_ID")
VERIFY_NONEXISTENT_HTTP_CODE=$(echo "$VERIFY_NONEXISTENT_RESPONSE" | tail -n1)
VERIFY_NONEXISTENT_BODY=$(echo "$VERIFY_NONEXISTENT_RESPONSE" | sed '$d')

if [ "$VERIFY_NONEXISTENT_HTTP_CODE" = "404" ] || [ "$VERIFY_NONEXISTENT_HTTP_CODE" = "400" ]; then
    print_success "✅ Non-existent user verification handled correctly (HTTP $VERIFY_NONEXISTENT_HTTP_CODE)"
    echo "Response: $VERIFY_NONEXISTENT_BODY"
else
    print_warning "⚠️  Non-existent user verification returned unexpected status (HTTP $VERIFY_NONEXISTENT_HTTP_CODE)"
    echo "Response: $VERIFY_NONEXISTENT_BODY"
fi

# Test 5: Register user with missing userId (should fail)
print_status "Test 5: Registering user with missing userId parameter..."
REGISTER_MISSING_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/register")
REGISTER_MISSING_HTTP_CODE=$(echo "$REGISTER_MISSING_RESPONSE" | tail -n1)
REGISTER_MISSING_BODY=$(echo "$REGISTER_MISSING_RESPONSE" | sed '$d')

if [ "$REGISTER_MISSING_HTTP_CODE" = "400" ]; then
    print_success "✅ Missing userId parameter handled correctly (HTTP $REGISTER_MISSING_HTTP_CODE)"
    echo "Response: $REGISTER_MISSING_BODY"
else
    print_warning "⚠️  Missing userId parameter returned unexpected status (HTTP $REGISTER_MISSING_HTTP_CODE)"
    echo "Response: $REGISTER_MISSING_BODY"
fi

# Test 6: Verify user with missing userId (should fail)
print_status "Test 6: Verifying user with missing userId parameter..."
VERIFY_MISSING_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/verify")
VERIFY_MISSING_HTTP_CODE=$(echo "$VERIFY_MISSING_RESPONSE" | tail -n1)
VERIFY_MISSING_BODY=$(echo "$VERIFY_MISSING_RESPONSE" | sed '$d')

if [ "$VERIFY_MISSING_HTTP_CODE" = "400" ]; then
    print_success "✅ Missing userId parameter handled correctly (HTTP $VERIFY_MISSING_HTTP_CODE)"
    echo "Response: $VERIFY_MISSING_BODY"
else
    print_warning "⚠️  Missing userId parameter returned unexpected status (HTTP $VERIFY_MISSING_HTTP_CODE)"
    echo "Response: $VERIFY_MISSING_BODY"
fi

echo ""
print_success "🎉 All tests completed!"
echo ""
print_status "📋 Test Summary:"
print_status "  - Python tests: Completed"
print_status "  - API endpoint tests: Completed"
print_status "  - Error handling tests: Completed"
echo ""
print_status "🔗 API Gateway URL: $API_URL"
print_status "📝 Test user ID: $TEST_USER_ID"
echo ""
print_status "🧪 To run tests again: ./scripts/test.sh"
print_status "🗑️  To clean up: ./scripts/destroy.sh" 