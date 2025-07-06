# Infrastructure as Code Assignment

This repository contains the implementation of a serverless user registration and verification system using AWS services and Terraform. The solution implements a secure and scalable architecture using API Gateway, Lambda, DynamoDB, and S3.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Deployment Instructions](#deployment-instructions)
  - [Setting up Remote State](#setting-up-remote-state)
  - [Deploying the Main Infrastructure](#deploying-the-main-infrastructure)
- [Testing](#testing)
- [Clean Up Instructions](#clean-up-instructions)
- [Design Decisions](#design-decisions)

## Architecture Overview

This solution implements a serverless architecture with the following components:

1. **API Gateway**: 
   - Serves as the entry point for all requests
   - Routes:
     - `/register` - For user registration
     - `/` - For user verification

2. **Lambda Functions**:
   - `register-user`: Handles user registration
   - `verify-user`: Validates user existence and returns appropriate HTML content

3. **DynamoDB**:
   - Stores user registration data
   - Uses PAY_PER_REQUEST billing mode for cost optimization

4. **S3 Bucket**:
   - Hosts static HTML content (index.html and error.html)
   - Serves success/error pages for user verification

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0.0
3. Python 3.8+ (for running tests)
4. Access to AWS Beach account #160071257600 (TW_CORE_BEACH_R_D)

## Project Structure

```
.
├── modules/               # Terraform modules
│   ├── api-gateway/      # API Gateway configuration
│   ├── dynamodb/         # DynamoDB table configuration
│   ├── lambda/           # Lambda functions configuration
│   └── s3/              # S3 bucket configuration
├── remote-state/         # Remote state configuration
├── src/                  # Application source code
│   ├── html/            # Static HTML files
│   └── lambda/          # Lambda function code
├── terraform/            # Main Terraform configuration
└── tests/               # Automated tests
```

## Deployment Instructions

### Setting up Remote State

1. Navigate to the remote state directory:
   ```bash
   cd remote-state
   ```

2. Initialize and apply the remote state configuration:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Deploying the Main Infrastructure

1. Navigate to the terraform directory:
   ```bash
   cd ../terraform
   ```

2. Initialize Terraform with the remote backend:
   ```bash
   terraform init
   ```

3. Deploy the infrastructure:
   ```bash
   terraform plan
   terraform apply
   ```

4. After successful deployment, you'll see outputs including:
   - API Gateway URL
   - S3 bucket ARN
   - DynamoDB table ARN

## Testing

1. Set up the test environment:
   ```bash
   cd tests
   python -m venv test-env
   source test-env/bin/activate  # On Windows: test-env\Scripts\activate
   pip install -r requirements.txt
   ```

2. Run the tests:
   ```bash
   pytest
   ```

The test suite includes:
- User registration with valid/invalid inputs
- User verification for registered/unregistered users
- Error handling for invalid requests
- Independent test cases that can run in isolation

## Clean Up Instructions

1. Remove all infrastructure:
   ```bash
   cd terraform
   terraform destroy
   ```

2. Clean up remote state resources:
   ```bash
   cd ../remote-state
   terraform destroy
   ```

Note: If you encounter issues destroying the S3 bucket due to content:
1. Empty the S3 bucket first:
   ```bash
   aws s3 rm s3://your-bucket-name --recursive
   ```
2. Then run terraform destroy again

## Design Decisions

1. **Security**:
   - Implemented least privilege principle for IAM roles
   - S3 bucket configured with appropriate access controls
   - API Gateway configured with necessary security measures

2. **Code Organization**:
   - Modular design for reusability and maintenance
   - Separation of concerns between infrastructure and application code
   - Clear separation of static content and Lambda functions

3. **Testing**:
   - Independent test cases for reliable validation
   - Comprehensive coverage of success and error scenarios
   - Environment isolation using Python virtual environments

4. **Cost Optimization**:
   - Use of PAY_PER_REQUEST for DynamoDB
   - Serverless architecture to minimize idle resource costs
   - Efficient resource cleanup procedures
