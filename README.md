# Infrastructure as Code - AWS Serverless User Management System

This repository contains a serverless user registration and verification system built with Terraform on AWS. The solution uses API Gateway, Lambda, DynamoDB, and S3 to create a secure and scalable application.

## 🔧 First Time Setup

Before deploying this infrastructure, you need to:

1. **Configure AWS CLI**:
   ```bash
   # Create and use AWS access credentials to configure the CLI
   aws configure
   
   # Verify your configuration
   aws sts get-caller-identity
   ```

2. **Review Environment Variables**:
   ```bash
   # Copy the environment example file and review it
   cp env.example .env
   
   # Edit the .env file with your preferred settings
   # Especially verify AWS region and any prefix values
   ```

3. **Prepare Lambda Code** (if making changes):
   ```bash
   # Install dependencies for Lambda functions
   cd src/lambda
   pip install -r requirements.txt -t .
   
   # Package Lambda functions
   cd ../..
   scripts/utilities/build-lambdas.sh
   ```

## 🏗️ Architecture

![Architecture Diagram](./images/assignment.png)

- **API Gateway**: Routes requests to appropriate Lambda functions
  - `/register` - User registration endpoint
  - `/` - User verification endpoint
- **Lambda Functions**: Process user requests
  - `register_user` - Saves users to DynamoDB
  - `verify_user` - Checks if users exist and returns appropriate HTML
- **DynamoDB**: Stores user data with on-demand capacity
- **S3 Bucket**: Hosts static HTML content (success/error pages)
- **CloudWatch**: Monitors Lambda execution and API Gateway requests

## 🚀 Quick Setup

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform v1.0+ installed
- GitHub account (for CI/CD)

### 1. Set Up Remote State Infrastructure

```bash
cd remote-state
terraform init
terraform apply
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking
- OIDC provider for GitHub Actions
- IAM role for GitHub Actions

### 2. Configure GitHub Repository

Add the following repository variables (not secrets) in your GitHub repository (Settings → Secrets and variables → Actions → Variables):

- `AWS_ACCOUNT_ID`: Your AWS account ID
- `S3_BUCKET_PREFIX`: Prefix for the S3 bucket (e.g., "iac-demo")
- `DYNAMODB_TABLE_PREFIX`: Prefix for the DynamoDB table (e.g., "iac-demo")
- `AWS_REGION`: Your AWS region (optional, defaults to us-east-1)

The workflow will automatically compute the full resource names using your GitHub username and repository name.

### 3. Deploy Main Infrastructure

**Option A: Using GitHub Actions (Recommended)**
- Push to the repository to trigger workflow
- Or manually run the workflow from the Actions tab

**Option B: Using Deployment Scripts**
```bash
# Execute the deployment script from the root directory
./deploy
```

**Option C: Manual Deployment**
```bash
cd terraform
terraform init \
  -backend-config="bucket=YOUR_S3_BUCKET" \
  -backend-config="dynamodb_table=YOUR_DYNAMODB_TABLE"
terraform apply
```

## 🧪 Testing

### Automated Tests

**Option A: Using Test Script**
```bash
# Run all tests with the test script
./test
```

**Option B: Manual Test Setup**
```bash
cd tests
python -m venv test-env
source test-env/bin/activate  # On Windows: test-env\Scripts\activate
pip install -r requirements.txt
pytest -v
```

### Manual Testing

Use the API Gateway URL from the Terraform output:

1. **Register a user**:
   ```bash
   curl -X PUT "https://[API_GATEWAY_URL]/register?userId=testuser123"
   ```

2. **Verify a user**:
   ```bash
   curl "https://[API_GATEWAY_URL]/?userId=testuser123"
   ```

You can also use the test script:
```bash
scripts/test-user-system.sh [API_GATEWAY_URL]
```

## 🧹 Cleanup

### Option A: Using GitHub Actions
Run the "destroy" workflow from the Actions tab

### Option B: Using Cleanup Script
```bash
# Execute the destroy script from the root directory
./destroy
```

### Option C: Manual Cleanup
```bash
# Clean up main infrastructure
cd terraform
terraform destroy

# Clean up remote state infrastructure
cd ../remote-state
terraform destroy
```

## 📁 Repository Structure

```
.
├── deploy                 # Deployment script
├── destroy                # Infrastructure cleanup script
├── test                   # Test execution script
├── .github/workflows/     # CI/CD pipeline definitions
├── modules/               # Terraform modules for each component
│   ├── api-gateway/       # API Gateway configuration
│   ├── dynamodb/          # DynamoDB table setup
│   ├── lambda/            # Lambda functions configuration
│   ├── monitoring/        # CloudWatch setup
│   └── s3/                # S3 bucket configuration
├── remote-state/          # Remote state infrastructure
├── reports/               # Generated reports
├── security-reports/      # Security scan results
├── scripts/               # Utility scripts
│   ├── deployment/        # Deployment helpers
│   ├── security/          # Security scanning tools
│   ├── testing/           # Test helpers
│   └── utilities/         # Miscellaneous utilities
├── src/                   # Application source code
│   ├── html/              # Static HTML files
│   └── lambda/            # Lambda function code
├── terraform/             # Main Terraform configuration
└── tests/                 # Test suite
```

## 🛡️ Security Features

- Least privilege IAM policies
- OIDC authentication for GitHub Actions
- CloudWatch logging and monitoring
- Resource encryption and secure configurations
- Automated security scanning via scripts/security/security-scan.sh

---

*For more detailed instructions for instructors, refer to the [INSTRUCTOR.md](./INSTRUCTOR.md)*
