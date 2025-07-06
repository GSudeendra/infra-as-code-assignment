# Infrastructure as Code Assignment - Milestone 2

## Table of Contents
1. [Updated Project Overview](#updated-project-overview)
2. [Prerequisites](#prerequisites)
3. [Remote State Setup](#remote-state-setup)
4. [How to Deploy the Infrastructure](#how-to-deploy-the-infrastructure)
5. [How to Test the Deployed Infrastructure](#how-to-test-the-deployed-infrastructure)
6. [How to Destroy the Infrastructure](#how-to-destroy-the-infrastructure)
7. [Automated Testing Instructions](#automated-testing-instructions)
8. [Outputs](#outputs)
9. [Architecture Details](#architecture-details)
10. [Troubleshooting](#troubleshooting)

## Updated Project Overview

This project implements a complete serverless user management system using AWS services. The system allows users to register and verify their accounts through REST API endpoints, with data persistence in DynamoDB and static content delivery from S3.

### Complete Architecture

The solution consists of the following AWS services working together:

- **API Gateway (HTTP API)**: Routes requests to appropriate Lambda functions
- **Lambda Functions**: 
  - `register_user`: Handles user registration and stores data in DynamoDB
  - `verify_user`: Verifies user existence and returns appropriate HTML content
- **DynamoDB**: NoSQL database for storing user information with PAY_PER_REQUEST billing
- **S3 Bucket**: Stores static HTML content (success and error pages)
- **CloudWatch**: Logging for Lambda functions
- **IAM**: Least privilege policies for all resources

### Data Flow
1. User sends PUT request to `/register?userId=<user_id>` → API Gateway → register_user Lambda → DynamoDB
2. User sends GET request to `/?userId=<user_id>` → API Gateway → verify_user Lambda → DynamoDB + S3 → HTML response

## Prerequisites

### AWS CLI Configuration
- AWS CLI installed and configured
- Access to AWS Beach account #160071257600
- AWS SSO profile configured (see AWS Configuration section below)

### Terraform Installation Requirements
- Terraform >= 1.0.0
- Local state management (will be migrated to remote state)

### Required AWS Permissions
The following permissions are required for deployment:
- S3: Create buckets, manage objects, configure encryption
- DynamoDB: Create tables, manage items
- Lambda: Create functions, manage execution roles
- API Gateway: Create HTTP APIs, manage routes and integrations
- IAM: Create roles and policies
- CloudWatch: Create log groups

### Python/Testing Framework Requirements
- Python 3.11+
- pip package manager
- pytest testing framework

### AWS Configuration

This project is configured to use the AWS Beach account (#160071257600) via AWS SSO. To set up your AWS configuration:

1. **Configure AWS SSO Profile:**
   ```bash
   # Login to AWS SSO
   aws sso login --profile twbeach
   
   # Configure the profile (if not already done)
   # ⚠️  SECURITY: Replace with your actual SSO configuration
   cat >> ~/.aws/config << 'EOF'
   [profile twbeach]
   sso_start_url = <your-sso-portal-url>
   sso_region = <sso-region>
   sso_account_id = 160071257600
   sso_role_name = <your-role-name>
   region = <aws-region>
   output = json
   EOF
   ```

2. **Validate AWS Account:**
   ```bash
   # Run the validation script to ensure correct account
   ./scripts/validate-aws-account.sh
   ```

3. **Environment Variables (Optional):**
   ```bash
   # Copy the example environment file
   cp env.example .env
   
   # Edit .env file if needed (DO NOT commit this file)
   # The AWS_PROFILE will be set automatically by the validation script
   ```

## Remote State Setup

This project uses remote state management with S3 for state storage and DynamoDB for state locking. Follow these steps to set up remote state infrastructure:

### Step 1: Deploy Remote State Infrastructure

```bash
# Navigate to remote state infrastructure directory
cd terraform-state-infra

# Initialize Terraform
terraform init

# Review the planned changes
terraform plan

# Apply the infrastructure
terraform apply
```

**Expected Output:**
```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

s3_bucket_name = "terraform-state-dev-XXXX"
dynamodb_table_name = "terraform-locks-dev-XXXX"
```

### Step 2: Update Backend Configuration

After deploying the remote state infrastructure, update the backend configuration in `terraform/backend.tf` with the actual values:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-dev-XXXX"  # Replace with actual bucket name
    key            = "iac-assignment/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-dev-XXXX"  # Replace with actual table name
    encrypt        = true
  }
}
```

### Step 3: Migrate to Remote State

```bash
# Navigate to main terraform directory
cd ../terraform

# Initialize with remote backend
terraform init

# Migrate state (if prompted, type 'yes')
```

## How to Deploy the Infrastructure

Follow these step-by-step instructions to deploy the complete infrastructure:

### Step 1: Validate Configuration

```bash
# Run validation script to check AWS account and configuration
./validate.sh
```

### Step 2: Deploy Remote State (if not already done)

```bash
cd terraform-state-infra
terraform init
terraform plan
terraform apply
cd ..
```

### Step 3: Update Backend Configuration

Update `terraform/backend.tf` with the actual S3 bucket and DynamoDB table names from Step 2.

### Step 4: Deploy Main Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Expected Output:**
```
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:

api_gateway_url = "https://abc123.execute-api.us-east-1.amazonaws.com"
s3_bucket_arn = "arn:aws:s3:::static-content-dev-XXXX"
dynamodb_table_arn = "arn:aws:dynamodb:us-east-1:160071257600:table/users-dev-XXXX"
lambda_function_names = {
  "register_user" = "dev-register_user-lambda-XXXX"
  "verify_user" = "dev-verify_user-lambda-XXXX"
}
```

### Step 5: Verify Deployment

```bash
# Get the API Gateway URL
export API_GATEWAY_URL=$(terraform output -raw api_gateway_url)
echo "API Gateway URL: $API_GATEWAY_URL"
```

## How to Test the Deployed Infrastructure

### Manual Testing Instructions

#### 1. Test User Registration

Register a user by sending a PUT request to the API Gateway `/register?userId=<user_id>` endpoint:

```bash
# Register a new user
curl -X PUT "${API_GATEWAY_URL}/register?userId=testuser123"
```

**Expected Response:**
```json
{
  "message": "User testuser123 registered successfully",
  "userId": "testuser123",
  "timestamp": "2024-01-15T10:30:00.123456"
}
```

#### 2. Test User Verification

Verify a user by sending a GET request to the API Gateway `/?userId=<user_id>` endpoint:

```bash
# Verify the registered user
curl "${API_GATEWAY_URL}/?userId=testuser123"
```

**Expected Response (Success):**
```html
<!DOCTYPE html>
<html>
<head>
    <title>User Verified Successfully</title>
    <style>...</style>
</head>
<body>
    <div class="container">
        <div class="success-icon">✓</div>
        <h1>Welcome!</h1>
        <p>User verification successful.</p>
        <p>You are now logged in to the system.</p>
    </div>
</body>
</html>
```

#### 3. Test Failed Verification

Test with a non-registered user:

```bash
# Verify a non-registered user
curl "${API_GATEWAY_URL}/?userId=nonexistentuser"
```

**Expected Response (Failure):**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Verification Failed</title>
    <style>...</style>
</head>
<body>
    <div class="container">
        <div class="error-icon">✗</div>
        <h1>Access Denied</h1>
        <p>User verification failed.</p>
        <p>Please check your credentials and try again.</p>
    </div>
</body>
</html>
```

#### 4. Test Error Handling

Test with invalid query strings:

```bash
# Test missing userId parameter
curl -X PUT "${API_GATEWAY_URL}/register"
curl "${API_GATEWAY_URL}/"

# Test empty userId parameter
curl -X PUT "${API_GATEWAY_URL}/register?userId="
curl "${API_GATEWAY_URL}/?userId="
```

**Expected Response:**
```json
{
  "error": "Missing userId parameter"
}
```

### Verify DynamoDB Records

```bash
# Check if user was created in DynamoDB
aws dynamodb get-item \
  --table-name users-dev-XXXX \
  --key '{"userId": {"S": "testuser123"}}' \
  --profile twbeach
```

### Verify S3 Content Delivery

```bash
# Check S3 bucket contents
aws s3 ls s3://static-content-dev-XXXX/ --profile twbeach

# Verify HTML files are accessible
aws s3 cp s3://static-content-dev-XXXX/index.html - --profile twbeach
aws s3 cp s3://static-content-dev-XXXX/error.html - --profile twbeach
```

## How to Destroy the Infrastructure

Follow these steps to completely destroy all infrastructure:

### Step 1: Destroy Main Infrastructure

```bash
cd terraform

# Check S3 bucket for objects
aws s3 ls s3://static-content-dev-XXXX/ --recursive --profile twbeach

# If bucket contains objects, delete them first
aws s3 rm s3://static-content-dev-XXXX --recursive --profile twbeach

# Destroy main infrastructure
terraform destroy
```

**Expected Output:**
```
Destroy complete! Resources: 15 destroyed.
```

### Step 2: Destroy Remote State Infrastructure

```bash
cd ../terraform-state-infra

# Destroy remote state infrastructure
terraform destroy
```

**Expected Output:**
```
Destroy complete! Resources: 2 destroyed.
```

### Step 3: Clean Up Local Files

```bash
# Remove Terraform directories
rm -rf terraform/.terraform
rm -rf terraform-state-infra/.terraform

# Remove plan files
rm -f terraform/tfplan
rm -f terraform-state-infra/tfplan

# Remove backup files
rm -f terraform/backend.tf.bak
```

## Automated Testing Instructions

### Step 1: Set Up Python Virtual Environment

```bash
# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

### Step 2: Install Test Dependencies

```bash
# Navigate to tests directory
cd tests

# Install requirements
pip install -r requirements.txt
```

**Expected Output:**
```
Collecting requests==2.31.0
  Downloading requests-2.31.0-py3-none-any.whl (62 kB)
Collecting pytest==7.4.0
  Downloading pytest-7.4.0-py3-none-any.whl (295 kB)
Collecting pytest-html==4.1.1
  Downloading pytest-html-4.1.1-py3-none-any.whl (15 kB)
Installing collected packages: ...
Successfully installed requests-2.31.0 pytest-7.4.0 pytest-html-4.1.1
```

### Step 3: Configure Test Environment

```bash
# Set API Gateway URL environment variable
export API_GATEWAY_URL=$(cd ../terraform && terraform output -raw api_gateway_url)
echo "API Gateway URL: $API_GATEWAY_URL"
```

### Step 4: Run Automated Tests

```bash
# Run all tests
pytest test_api.py -v

# Run specific test categories
pytest test_api.py::TestAPI::test_register_user_success -v
pytest test_api.py::TestAPI::test_verify_registered_user -v
pytest test_api.py::TestAPI::test_verify_non_registered_user -v
```

**Expected Output:**
```
test_api.py::TestAPI::test_register_user_success PASSED
test_api.py::TestAPI::test_register_user_invalid_query PASSED
test_api.py::TestAPI::test_register_user_empty_userid PASSED
test_api.py::TestAPI::test_verify_registered_user PASSED
test_api.py::TestAPI::test_verify_non_registered_user PASSED
test_api.py::TestAPI::test_verify_user_invalid_query PASSED
test_api.py::TestAPI::test_verify_user_empty_userid PASSED
test_api.py::TestAPI::test_register_user_multiple_times PASSED
test_api.py::TestAPI::test_verify_user_independent_test PASSED
test_api.py::TestAPI::test_api_gateway_health_check PASSED

10 passed in 5.23s
```

### Test Independence Verification

Each test is designed to be independent and can run in isolation:

```bash
# Run a single test that creates its own user
pytest test_api.py::TestAPI::test_verify_user_independent_test -v -s
```

## Outputs

### Terraform Outputs Description

The following outputs are available after successful deployment:

#### API Gateway URL
- **Description**: The public URL of the deployed API Gateway
- **Usage**: Used for testing endpoints and integration
- **Retrieve**: `terraform output -raw api_gateway_url`

#### S3 Bucket ARN
- **Description**: ARN of the S3 bucket for static content
- **Usage**: Reference for IAM policies and monitoring
- **Retrieve**: `terraform output -raw s3_bucket_arn`

#### DynamoDB Table ARN
- **Description**: ARN of the DynamoDB table for user storage
- **Usage**: Reference for IAM policies and monitoring
- **Retrieve**: `terraform output -raw dynamodb_table_arn`

#### Lambda Function Names
- **Description**: Names of the deployed Lambda functions
- **Usage**: Reference for CloudWatch logs and monitoring
- **Retrieve**: `terraform output lambda_function_names`

### Example Output Retrieval

```bash
# Get all outputs
terraform output

# Get specific outputs
export API_GATEWAY_URL=$(terraform output -raw api_gateway_url)
export S3_BUCKET_ARN=$(terraform output -raw s3_bucket_arn)
export DYNAMODB_TABLE_ARN=$(terraform output -raw dynamodb_table_arn)
```

## Architecture Details

### Component Interactions

1. **API Gateway Routes**:
   - `PUT /register` → register_user Lambda
   - `GET /` → verify_user Lambda

2. **Lambda Functions**:
   - **register_user**: Receives userId, validates input, stores in DynamoDB
   - **verify_user**: Receives userId, checks DynamoDB, returns S3 HTML content

3. **Data Storage**:
   - **DynamoDB**: Stores user records with userId as primary key
   - **S3**: Stores static HTML files (index.html, error.html)

### Security Considerations

#### IAM Policies (Least Privilege Principle)

**Lambda Execution Roles**:
- CloudWatch Logs access for logging
- DynamoDB access for user data operations
- S3 read access for HTML content (verify_user only)

**API Gateway**:
- Lambda invocation permissions for each function
- No direct access to other AWS services

#### Data Security
- All resources use encryption at rest
- S3 bucket is private with no public access
- DynamoDB uses server-side encryption
- API Gateway uses HTTPS endpoints

### Design Decisions

1. **PAY_PER_REQUEST Billing**: DynamoDB uses on-demand billing to avoid idle costs
2. **HTTP API**: Chosen over REST API for simplicity and cost-effectiveness
3. **Modular Design**: Terraform modules for reusability and maintainability
4. **Environment Variables**: Lambda functions use environment variables for configuration
5. **Static Content**: S3 serves HTML content to reduce Lambda complexity

## Troubleshooting

### Common Issues and Solutions

#### 1. Lambda Function Errors

**Problem**: Lambda functions failing with permission errors
**Solution**: Check IAM policies and environment variables

```bash
# Check Lambda logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/dev-" --profile twbeach

# View recent logs
aws logs tail /aws/lambda/dev-register_user-lambda-XXXX --profile twbeach
```

#### 2. API Gateway Issues

**Problem**: API Gateway returning 500 errors
**Solution**: Verify Lambda permissions and integration settings

```bash
# Check API Gateway logs (if enabled)
aws logs describe-log-groups --log-group-name-prefix "API-Gateway-Execution-Logs" --profile twbeach
```

#### 3. DynamoDB Access Issues

**Problem**: Lambda cannot access DynamoDB table
**Solution**: Verify table name and IAM permissions

```bash
# Check if table exists
aws dynamodb describe-table --table-name users-dev-XXXX --profile twbeach

# Test table access
aws dynamodb put-item \
  --table-name users-dev-XXXX \
  --item '{"userId": {"S": "test"}}' \
  --profile twbeach
```

#### 4. S3 Access Issues

**Problem**: Lambda cannot read S3 content
**Solution**: Verify bucket name and IAM permissions

```bash
# Check if bucket exists
aws s3 ls s3://static-content-dev-XXXX/ --profile twbeach

# Test bucket access
aws s3 cp s3://static-content-dev-XXXX/index.html - --profile twbeach
```

### Debug Lambda Functions Using CloudWatch Logs

1. **Access CloudWatch Console**:
   - Navigate to AWS Console → CloudWatch → Log Groups
   - Find log group: `/aws/lambda/dev-register_user-lambda-XXXX`

2. **View Recent Logs**:
   ```bash
   aws logs tail /aws/lambda/dev-register_user-lambda-XXXX --profile twbeach
   ```

3. **Filter Logs**:
   ```bash
   aws logs filter-log-events \
     --log-group-name "/aws/lambda/dev-register_user-lambda-XXXX" \
     --filter-pattern "ERROR" \
     --profile twbeach
   ```

### Verify DynamoDB Operations

```bash
# List all items in table
aws dynamodb scan --table-name users-dev-XXXX --profile twbeach

# Get specific user
aws dynamodb get-item \
  --table-name users-dev-XXXX \
  --key '{"userId": {"S": "testuser123"}}' \
  --profile twbeach
```

### Check S3 Permissions and Content

```bash
# List bucket contents
aws s3 ls s3://static-content-dev-XXXX/ --recursive --profile twbeach

# Check bucket policy
aws s3api get-bucket-policy --bucket static-content-dev-XXXX --profile twbeach

# Test content access
aws s3 cp s3://static-content-dev-XXXX/index.html - --profile twbeach
```

### Environment Variable Issues

```bash
# Check Lambda environment variables
aws lambda get-function-configuration \
  --function-name dev-register_user-lambda-XXXX \
  --query 'Environment.Variables' \
  --profile twbeach
```

### Network and Connectivity Issues

```bash
# Test API Gateway connectivity
curl -v "${API_GATEWAY_URL}/"

# Test Lambda function directly (if needed)
aws lambda invoke \
  --function-name dev-register_user-lambda-XXXX \
  --payload '{"queryStringParameters": {"userId": "test"}}' \
  response.json \
  --profile twbeach
```

## Security Best Practices

⚠️ **Important Security Notes:**

1. **SSO Configuration**: 
   - Never commit SSO URLs or sensitive configuration to version control
   - Use placeholder values in documentation (e.g., `<your-sso-portal-url>`)
   - Configure actual SSO settings in your local `~/.aws/config`

2. **Account Validation**:
   - The validation script only checks the account ID, not the SSO configuration
   - Ensure your local AWS configuration is secure and up-to-date

3. **Access Control**:
   - Use least privilege IAM roles
   - Regularly rotate SSO sessions
   - Monitor AWS CloudTrail for suspicious activity

4. **Code Security**:
   - No hardcoded credentials or sensitive URLs in the codebase
   - All sensitive configuration uses environment variables or AWS profiles
   - `.env` files are excluded from version control

## Cost Optimization

- **DynamoDB**: Uses PAY_PER_REQUEST billing (no idle costs)
- **Lambda Functions**: Minimal memory allocation (128 MB)
- **S3 Bucket**: Lifecycle policies can be added for cost management
- **CloudWatch Logs**: 7-day retention to minimize storage costs
- **API Gateway**: HTTP API (more cost-effective than REST API)

## Future Enhancements

Potential improvements for future milestones:
- Add authentication and authorization
- Implement user profile management
- Add data validation and sanitization
- Implement rate limiting
- Add monitoring and alerting
- Implement CI/CD pipeline with GitHub Actions
