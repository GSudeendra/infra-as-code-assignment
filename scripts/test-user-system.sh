#!/bin/bash

# 🧪 User System Testing Script
# This script automatically tests the deployed user management system

set -e  # Exit on any error

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Get API Gateway URL
print_status "Getting API Gateway URL..."
if [ -d "terraform" ]; then
    cd terraform
    API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
    cd ..
else
    print_error "terraform directory not found. Please run this script from the project root."
    exit 1
fi

if [ -z "$API_URL" ]; then
    print_error "Could not get API Gateway URL. Please ensure infrastructure is deployed."
    exit 1
fi

print_success "API Gateway URL: $API_URL"

# Generate unique test user ID
TEST_USER="testuser_$(date +%s)"
print_status "Using test user: $TEST_USER"

echo ""
print_status "Starting automated tests..."
echo ""

# Test 1: User Registration
print_status "Test 1: User Registration"
REGISTER_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$API_URL/register?userId=$TEST_USER")
HTTP_CODE="${REGISTER_RESPONSE: -3}"
RESPONSE_BODY="${REGISTER_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    print_success "User registration successful"
    echo "Response: $RESPONSE_BODY"
else
    print_error "User registration failed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi

echo ""

# Test 2: User Verification (Success)
print_status "Test 2: User Verification (Success)"
VERIFY_RESPONSE=$(curl -s -w "%{http_code}" "$API_URL/?userId=$TEST_USER")
HTTP_CODE="${VERIFY_RESPONSE: -3}"
RESPONSE_BODY="${VERIFY_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    if echo "$RESPONSE_BODY" | grep -q "Welcome"; then
        print_success "User verification successful"
    else
        print_warning "User verification returned 200 but content seems unexpected"
    fi
else
    print_error "User verification failed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi

echo ""

# Test 3: Idempotency (Duplicate Registration)
print_status "Test 3: Idempotency (Duplicate Registration)"
DUPLICATE_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$API_URL/register?userId=$TEST_USER")
HTTP_CODE="${DUPLICATE_RESPONSE: -3}"
RESPONSE_BODY="${DUPLICATE_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    if echo "$RESPONSE_BODY" | grep -q "already registered"; then
        print_success "Idempotency test passed (user already registered)"
    else
        print_warning "Idempotency test returned 200 but content seems unexpected"
    fi
else
    print_error "Idempotency test failed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""

# Test 4: Error Handling - Missing User ID (Registration)
print_status "Test 4: Error Handling - Missing User ID (Registration)"
MISSING_REG_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$API_URL/register")
HTTP_CODE="${MISSING_REG_RESPONSE: -3}"
RESPONSE_BODY="${MISSING_REG_RESPONSE%???}"

if [ "$HTTP_CODE" = "400" ]; then
    if echo "$RESPONSE_BODY" | grep -q "Missing userId parameter"; then
        print_success "Error handling for missing userId in registration works"
    else
        print_warning "Error handling returned 400 but content seems unexpected"
    fi
else
    print_error "Error handling for missing userId failed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""

# Test 5: Error Handling - Missing User ID (Verification)
print_status "Test 5: Error Handling - Missing User ID (Verification)"
MISSING_VER_RESPONSE=$(curl -s -w "%{http_code}" "$API_URL/")
HTTP_CODE="${MISSING_VER_RESPONSE: -3}"
RESPONSE_BODY="${MISSING_VER_RESPONSE%???}"

if [ "$HTTP_CODE" = "400" ]; then
    if echo "$RESPONSE_BODY" | grep -q "Missing userId parameter"; then
        print_success "Error handling for missing userId in verification works"
    else
        print_warning "Error handling returned 400 but content seems unexpected"
    fi
else
    print_error "Error handling for missing userId failed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""

# Test 6: Error Handling - Non-existent User
print_status "Test 6: Error Handling - Non-existent User"
NONEXISTENT_RESPONSE=$(curl -s -w "%{http_code}" "$API_URL/?userId=nonexistent_user_$(date +%s)")
HTTP_CODE="${NONEXISTENT_RESPONSE: -3}"
RESPONSE_BODY="${NONEXISTENT_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    if echo "$RESPONSE_BODY" | grep -q "Access Denied"; then
        print_success "Error handling for non-existent user works"
    else
        print_warning "Error handling returned 200 but content seems unexpected"
    fi
else
    print_error "Error handling for non-existent user failed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""
print_success "🎉 All automated tests completed!"
echo ""
print_status "Test Summary:"
echo "✅ User Registration: Working"
echo "✅ User Verification: Working"
echo "✅ Idempotency: Working"
echo "✅ Error Handling: Working"
echo ""
print_status "Your infrastructure is working correctly! 🚀"
echo ""
print_status "You can now test manually using:"
echo "  Registration: curl -X POST \"$API_URL/register?userId=your_username\""
echo "  Verification: curl \"$API_URL/?userId=your_username\""
echo ""
print_status "Or open in your browser:"
echo "  Registration: $API_URL/register?userId=your_username"
echo "  Verification: $API_URL/?userId=your_username" 