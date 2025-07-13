# Getting Started: Essential AWS Setup

Before using this project, you must set up AWS resources for secure GitHub Actions authentication and Terraform remote state. **These steps are required for all new environments!**

## 1. Deploy Remote State and OIDC Role

From your project root, run:

```sh
cd remote-state
terraform init
terraform apply
```
- This will create:
  - S3 bucket for Terraform state
  - DynamoDB table for state locking
  - OIDC provider for GitHub Actions
  - IAM role for GitHub Actions OIDC authentication

## 2. Find the IAM Role ARN
- Go to AWS Console → IAM → Roles
- Search for your role (e.g., `iacdemo-github-actions-role-dev`)
- Click the role and copy the **Role ARN** (e.g., `arn:aws:iam::160071257600:role/iacdemo-github-actions-role-dev`)

## 3. Configure GitHub Secrets
- Go to your GitHub repo → Settings → Secrets and variables → Actions
- Add the following secrets:

| Secret Name      | Value (example)                                                        |
|------------------|------------------------------------------------------------------------|
| AWS_ROLE_ARN     | arn:aws:iam::160071257600:role/iacdemo-github-actions-role-dev         |
| S3_BUCKET_NAME   | iacdemo-terraform-state-dev                                            |
| DYNAMODB_TABLE   | iacdemo-terraform-locks-dev                                            |

- Use the actual values output by Terraform, not the placeholders above.

## 4. Re-run Your GitHub Actions Pipeline
- Your pipeline will now be able to authenticate to AWS and manage infrastructure securely.

---

# Infrastructure as Code Assignment - Milestone 3

This repository contains the implementation of a serverless user registration and verification system using AWS services and Terraform, now enhanced with CI/CD automation, advanced Terraform modules, comprehensive testing, and enterprise-grade security.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Milestone 3 Features](#milestone-3-features)
- [Security Features](#security-features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Deployment Instructions](#deployment-instructions)
  - [Setting up Remote State](#setting-up-remote-state)
  - [Configuring GitHub Actions](#configuring-github-actions)
  - [Deploying the Main Infrastructure](#deploying-the-main-infrastructure)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security Testing](#security-testing)
- [Testing](#testing)
- [Clean Up Instructions](#clean-up-instructions)
- [Design Decisions](#design-decisions)
- [Instructor Guide](#instructor-guide)

## Architecture Overview

This solution implements a serverless architecture with the following components:

1. **API Gateway**: 
   - Serves as the entry point for all requests
   - Routes:
     - `/register` - For user registration
     - `/` - For user verification
   - **Security**: Access logging, authorization controls, CORS configuration

2. **Lambda Functions**:
   - `register-user`: Handles user registration
   - `verify-user`: Validates user existence and returns appropriate HTML content
   - **Security**: X-Ray tracing, restricted IAM policies, concurrent execution limits

3. **DynamoDB**:
   - Stores user registration data
   - Uses PAY_PER_REQUEST billing mode for cost optimization
   - **Security**: Server-side encryption, point-in-time recovery

4. **S3 Bucket**:
   - Hosts static HTML content (index.html and error.html)
   - Serves success/error pages for user verification
   - **Security**: Encryption, access logging, lifecycle policies, public access restrictions

5. **CloudWatch Monitoring**:
   - Log groups for Lambda functions
   - Alarms for errors and performance metrics
   - API Gateway monitoring
   - **Security**: KMS encryption, extended log retention

## Milestone 3 Features

### 🚀 CI/CD Automation
- **GitHub Actions Workflow**: Automated deployment, testing, and destruction
- **OIDC Authentication**: Secure AWS access without stored credentials
- **Security Scanning**: Checkov integration for infrastructure security
- **Code Quality**: TFLint validation and formatting checks

### 🧩 Terraform Modules
- **Modular Architecture**: Reusable components for better organization
- **Custom Monitoring Module**: CloudWatch alarms and logging configuration
- **Standardized Patterns**: Consistent resource naming and tagging

### 🔒 Security & Best Practices
- **Least Privilege Access**: Granular IAM permissions
- **Security Scanning**: Automated vulnerability detection
- **Remote State Management**: S3 + DynamoDB for state storage and locking
- **OIDC Authentication**: No long-term AWS credentials

### 🧪 Comprehensive Testing
- **Infrastructure Tests**: AWS resource validation
- **Application Tests**: API functionality verification
- **Security Tests**: Configuration validation
- **Automated Pipeline**: Tests run on every deployment

## Security Features

### 🛡️ Enterprise-Grade Security Implementation

This infrastructure implements comprehensive security measures to meet enterprise standards:

#### **API Gateway Security**
- ✅ Access logging with detailed request/response data
- ✅ Explicit authorization type declarations
- ✅ CORS configuration with proper headers
- ✅ CloudWatch integration for monitoring

#### **Lambda Security**
- ✅ X-Ray tracing for request tracing and debugging
- ✅ Concurrent execution limits to prevent resource exhaustion
- ✅ Restricted IAM policies with resource-specific permissions
- ✅ Environment variable encryption support
- ✅ Optional VPC configuration for network isolation

#### **DynamoDB Security**
- ✅ Server-side encryption with AWS managed keys
- ✅ Point-in-time recovery for data protection
- ✅ Access logging and monitoring
- ✅ Backup encryption

#### **S3 Security**
- ✅ Server-side encryption with bucket key optimization
- ✅ Access logging to separate bucket
- ✅ Public access completely blocked
- ✅ Lifecycle policies for cost management
- ✅ Versioning enabled for data protection

#### **CloudWatch Security**
- ✅ KMS encryption for log groups
- ✅ Extended retention (minimum 1 year)
- ✅ Comprehensive monitoring and alerting
- ✅ Access control through IAM policies

#### **IAM Security**
- ✅ Principle of least privilege
- ✅ Resource-specific permissions (no wildcards)
- ✅ Environment-based access controls
- ✅ Regular policy reviews and updates

### 🔍 Security Scanning & Compliance

#### **Automated Security Tools**
- **Checkov**: Infrastructure security scanning
- **TFLint**: Terraform best practices validation
- **Bandit**: Python code security analysis
- **Terraform Validate**: Configuration validation

#### **Compliance Standards**
- **SOC 2**: Data encryption, access logging, monitoring
- **PCI DSS**: Encryption at rest, access controls
- **HIPAA**: Data protection, audit logging
- **ISO 27001**: Information security management

#### **Security Testing**
- Comprehensive security testing guide
- Automated security scanning scripts
- Manual verification procedures
- Continuous monitoring and alerting

### 📋 Security Documentation
- [Security Fixes Applied](SECURITY_FIXES.md) - Detailed security improvements
- [Security Testing Guide](SECURITY_TESTING_GUIDE.md) - Comprehensive testing procedures
- [Checkov Configuration](.checkov.yaml) - Security scanning configuration
- [Security Scanning Script](scripts/security/security-scan.sh) - Automated security checks

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.5.0
3. Python 3.9+ (for running tests)
4. GitHub account
5. Access to AWS Beach account #160071257600 (TW_CORE_BEACH_R_D)

## Project Structure

```
.
├── .github/workflows/     # GitHub Actions workflows
│   └── deploy.yaml       # Main CI/CD workflow
├── modules/              # Terraform modules
│   ├── api-gateway/     # API Gateway configuration
│   ├── dynamodb/        # DynamoDB table configuration
│   ├── lambda/          # Lambda functions configuration
│   ├── s3/             # S3 bucket configuration
│   └── monitoring/     # CloudWatch monitoring module
├── remote-state/        # Remote state infrastructure
│   ├── main.tf         # S3 bucket and DynamoDB table
│   ├── github-oidc.tf  # GitHub OIDC provider and IAM role
│   ├── variables.tf    # Variables for remote state
│   └── outputs.tf      # Outputs from remote state
├── src/                 # Application source code
│   ├── html/           # Static HTML files
│   └── lambda/         # Lambda function code
├── terraform/           # Main Terraform configuration
├── tests/              # Automated tests
│   ├── test_user_management_api.py  # Application tests
│   └── test_infrastructure.py       # Infrastructure tests
├── .tflint.hcl         # TFLint configuration
├── INSTRUCTOR_GUIDE.md # Guide for instructors
└── README.md           # This file
```

## Deployment Instructions

### 🚀 Quick Setup for Instructors

**For instructors who want to quickly set up and test the repository:**

1. **Run the automated setup script**:
   ```bash
   ./scripts/setup-instructor.sh
   ```
   
   This script will:
   - Check all prerequisites (AWS CLI, Terraform, Python)
   - Configure GitHub OIDC for your repository
   - Deploy remote state infrastructure (S3 + DynamoDB)
   - Update backend configuration automatically
   - Test the setup and provide next steps

2. **Add GitHub Repository Secret**:
   - Go to your GitHub repository → Settings → Secrets and Variables → Actions
   - Add secret: `AWS_ROLE_ARN` with the value from the setup script output

3. **Push to trigger CI/CD**:
   ```bash
   git add .
   git commit -m "Setup Milestone 3 infrastructure"
   git push origin main
   ```

### Manual Setup (Alternative)

If you prefer manual setup or need to customize the configuration:

#### Setting up Remote State

1. Navigate to the remote state directory:
   ```bash
   cd remote-state
   ```

2. Update the GitHub OIDC configuration in `github-oidc.tf`:
   ```hcl
   # Change this line with your GitHub username and repository name
   "token.actions.githubusercontent.com:sub" = "repo:YOUR_USERNAME/YOUR_REPO_NAME:*"
   ```

3. Initialize and apply the remote state configuration:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Save the outputs for later use:
   - `s3_bucket_name`: S3 bucket for Terraform state
   - `dynamodb_table_name`: DynamoDB table for state locking
   - `github_actions_role_arn`: GitHub Actions IAM role ARN

#### Configuring GitHub Actions

1. **Add Repository Secret**:
   - Go to your GitHub repository → Settings → Secrets and Variables → Actions
   - Add secret: `AWS_ROLE_ARN` with the GitHub Actions role ARN from step 4

2. **Update Backend Configuration**:
   Edit `terraform/backend.tf` with your actual bucket and table names:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "YOUR_S3_BUCKET_NAME"
       key            = "terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "YOUR_DYNAMODB_TABLE_NAME"
       encrypt        = true
     }
   }
   ```

### Deploying the Main Infrastructure

#### Automated Deployment (Recommended)

1. **Push to Main Branch**: Automatically triggers deployment
   ```bash
   git add .
   git commit -m "Deploy infrastructure"
   git push origin main
   ```

2. **Manual Workflow Trigger**: 
   - Go to GitHub Actions tab in your repository
   - Select "Deploy Infrastructure" workflow
   - Click "Run workflow"
   - Choose action: `plan`, `apply`, or `destroy`

#### Manual Deployment (Alternative)

1. Navigate to the terraform directory:
   ```bash
   cd terraform
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

## CI/CD Pipeline

### GitHub Actions Workflow

The pipeline includes the following stages:

1. **Code Quality Checks**:
   - Terraform formatting validation
   - TFLint static analysis
   - Security scanning with Checkov

2. **Deployment Stages**:
   - Plan (on pull requests)
   - Apply (on main branch pushes)
   - Infrastructure testing
   - Optional destroy

3. **Security Features**:
   - OIDC authentication with AWS
   - Least privilege IAM policies
   - Security scanning reports

### Workflow Triggers

- **Push to main**: Automatically deploys infrastructure
- **Pull Request**: Runs plan and validation checks
- **Manual Dispatch**: Allows manual control over plan/apply/destroy

### Security Scanning

The pipeline includes automated security scanning using Checkov:
- Scans Terraform code for security misconfigurations
- Generates SARIF reports for GitHub Security tab
- Fails pipeline on critical security issues

## Security Testing

### Automated Security Scanning

The CI/CD pipeline includes comprehensive security scanning:

#### **Checkov Infrastructure Security**
- Scans Terraform code for security misconfigurations
- Generates SARIF reports for GitHub Security tab
- Fails pipeline on critical security issues
- Configurable suppressions for known false positives

#### **TFLint Best Practices**
- Validates Terraform code against best practices
- Ensures consistent formatting and naming
- Checks for deprecated syntax and patterns

#### **Bandit Python Security**
- Scans Python code for security vulnerabilities
- Identifies common security issues
- Generates detailed security reports

### Manual Security Testing

#### **Quick Security Scan**
```bash
# Run comprehensive security scan
chmod +x scripts/security/security-scan.sh
./scripts/security/security-scan.sh
```

#### **Individual Security Checks**
```bash
# Checkov scan
checkov -d . --quiet --output sarif --output-file-path reports/results.sarif

# TFLint validation
tflint --init && tflint --recursive

# Terraform validation
terraform validate
```

### Security Verification Commands

#### **API Gateway Security**
```bash
# Verify access logging
aws logs describe-log-groups --log-group-name-prefix "/aws/apigateway"

# Check authorization settings
aws apigatewayv2 get-stage --api-id <API_ID> --stage-name '$default'
```

#### **Lambda Security**
```bash
# Verify X-Ray tracing
aws lambda get-function --function-name <FUNCTION_NAME> \
  --query 'Configuration.TracingConfig'

# Check IAM permissions
aws iam get-role-policy --role-name <ROLE_NAME> --policy-name <POLICY_NAME>
```

#### **DynamoDB Security**
```bash
# Verify encryption
aws dynamodb describe-table --table-name <TABLE_NAME> \
  --query 'Table.SSEDescription'

# Check backup settings
aws dynamodb describe-continuous-backups --table-name <TABLE_NAME>
```

#### **S3 Security**
```bash
# Verify encryption
aws s3api get-bucket-encryption --bucket <BUCKET_NAME>

# Check public access
aws s3api get-public-access-block --bucket <BUCKET_NAME>
```

### Security Compliance

The infrastructure meets multiple compliance standards:

- **SOC 2**: Data encryption, access logging, monitoring
- **PCI DSS**: Encryption at rest, access controls
- **HIPAA**: Data protection, audit logging
- **ISO 27001**: Information security management

### Security Documentation

- [Security Fixes Applied](SECURITY_FIXES.md) - Detailed security improvements
- [Security Testing Guide](SECURITY_TESTING_GUIDE.md) - Comprehensive testing procedures
- [Checkov Configuration](.checkov.yaml) - Security scanning configuration

## Testing

### Automated Testing

Tests run automatically as part of the CI/CD pipeline after successful deployment.

### Manual Testing

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

### Test Coverage

The test suite includes:

#### Application Tests (`test_user_management_api.py`)
- User registration with valid/invalid inputs
- User verification for registered/unregistered users
- Error handling for invalid requests
- Independent test cases that can run in isolation

#### Infrastructure Tests (`test_infrastructure.py`)
- S3 bucket existence and configuration
- DynamoDB table validation
- Lambda function verification
- API Gateway accessibility
- Security settings validation
- CloudWatch log groups
- Cost optimization checks

## Clean Up Instructions

### Automated Destruction

1. **Via GitHub Actions**:
   - Go to Actions tab → Deploy Infrastructure
   - Click "Run workflow"
   - Select "destroy" action
   - Run workflow

### Manual Destruction

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

### Complete Cleanup

To remove all resources including remote state:

```bash
# 1. Destroy main infrastructure
cd terraform
terraform destroy

# 2. Destroy remote state infrastructure
cd ../remote-state
terraform destroy

# 3. Manually delete any remaining S3 objects if needed
aws s3 rm s3://your-state-bucket-name --recursive
```

**Note**: If you encounter issues destroying the S3 bucket due to content:
1. Empty the S3 bucket first:
   ```bash
   aws s3 rm s3://your-bucket-name --recursive
   ```
2. Then run terraform destroy again

## Design Decisions

### 1. **CI/CD Architecture**
- **GitHub Actions**: Native integration with repository, OIDC support
- **OIDC Authentication**: Secure AWS access without stored credentials
- **Modular Workflow**: Separate jobs for different concerns (format, lint, security, deploy)

### 2. **Terraform Modules**
- **Modular Design**: Reusable components for better organization
- **Custom Monitoring Module**: Encapsulates CloudWatch configuration
- **Standardized Patterns**: Consistent resource naming and tagging

### 3. **Security**
- **Least Privilege**: Granular IAM permissions for each service
- **OIDC Authentication**: No long-term AWS credentials in GitHub
- **Security Scanning**: Automated vulnerability detection
- **Remote State**: Encrypted state storage with locking

### 4. **Testing Strategy**
- **Infrastructure Tests**: Validate AWS resource configuration
- **Application Tests**: Verify API functionality
- **Security Tests**: Check configuration compliance
- **Automated Pipeline**: Tests run on every deployment

### 5. **Cost Optimization**
- **PAY_PER_REQUEST**: DynamoDB billing mode for cost efficiency
- **Serverless Architecture**: Minimize idle resource costs
- **Efficient Cleanup**: Proper resource destruction procedures

### 6. **Monitoring and Observability**
- **CloudWatch Logs**: Centralized logging for Lambda functions
- **Performance Alarms**: Monitor Lambda duration and errors
- **API Monitoring**: Track API Gateway errors and performance

## Instructor Guide

This section provides detailed instructions for instructors to evaluate the project.

### 🎯 Evaluation Checklist

#### **Prerequisites for Instructors**
- [ ] AWS CLI configured with appropriate credentials
- [ ] Terraform >= 1.5.0 installed
- [ ] Python 3.9+ installed
- [ ] GitHub account with repository access

#### **Setup Steps for Instructors**

1. **Fork the Repository**:
   - Fork the repository to your GitHub account
   - Clone the forked repository locally

2. **Run Automated Setup**:
   ```bash
   ./scripts/setup-instructor.sh
   ```
   - This will configure everything automatically
   - Follow the prompts and save the output values

3. **Configure GitHub Secrets**:
   - Go to your forked repository → Settings → Secrets and Variables → Actions
   - Add secret: `AWS_ROLE_ARN` with the value from the setup script

4. **Test the CI/CD Pipeline**:
   ```bash
   git add .
   git commit -m "Test Milestone 3 setup"
   git push origin main
   ```
   - Monitor the GitHub Actions workflow
   - Verify successful deployment

#### **What to Look For**

##### **✅ CI/CD Pipeline Features**
- [ ] GitHub Actions workflow runs successfully
- [ ] OIDC authentication works (no stored AWS credentials)
- [ ] Security scanning (Checkov) runs and reports issues
- [ ] Code quality checks (TFLint, formatting) pass
- [ ] Automated testing runs after deployment
- [ ] Manual workflow dispatch works (plan/apply/destroy)

##### **✅ Infrastructure Features**
- [ ] All AWS resources deploy successfully
- [ ] API Gateway serves the application
- [ ] Lambda functions work correctly
- [ ] DynamoDB stores and retrieves data
- [ ] S3 hosts static content
- [ ] CloudWatch monitoring is configured

##### **✅ Security Features**
- [ ] Least privilege IAM policies
- [ ] Encryption enabled on all resources
- [ ] Security scanning passes
- [ ] No hardcoded credentials
- [ ] OIDC authentication configured

##### **✅ Testing Features**
- [ ] Infrastructure tests pass
- [ ] Application tests pass
- [ ] Security tests run
- [ ] Tests are automated in CI/CD

#### **Common Issues and Solutions**

**Issue**: `terraform init` fails with credential errors
- **Solution**: Ensure AWS credentials are configured and the IAM role has proper permissions

**Issue**: GitHub Actions workflow fails on credential step
- **Solution**: Verify the `AWS_ROLE_ARN` secret is set correctly in repository settings

**Issue**: Security scanning fails
- **Solution**: Check that all security tools are installed and the reports directory exists

**Issue**: Tests fail after deployment
- **Solution**: Ensure the infrastructure is fully deployed before running tests

#### **Manual Testing Commands**

```bash
# Test API Gateway
curl -X POST "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/register" \
  -H "Content-Type: application/json" \
  -d '{"userId": "test-user", "email": "test@example.com"}'

# Test Lambda functions directly
aws lambda invoke --function-name register-user-lambda \
  --payload '{"userId": "test", "email": "test@example.com"}' response.json

# Check DynamoDB
aws dynamodb scan --table-name users-table

# Verify S3 content
aws s3 ls s3://YOUR_BUCKET_NAME/
```

#### **Cleanup Instructions**

1. **Destroy Infrastructure**:
   - Go to GitHub Actions → Deploy Infrastructure → Run workflow
   - Choose action: `destroy`
   - This will empty S3 buckets and destroy all resources

2. **Manual Cleanup** (if needed):
   ```bash
   cd terraform
   terraform destroy -auto-approve
   cd ../remote-state
   terraform destroy -auto-approve
   ```

#### **Grading Criteria**

| Criteria | Points | Description |
|----------|--------|-------------|
| CI/CD Pipeline | 25 | GitHub Actions workflow, OIDC, security scanning |
| Infrastructure | 25 | All AWS resources deploy and work correctly |
| Security | 20 | Encryption, IAM policies, security scanning |
| Testing | 15 | Automated tests, infrastructure validation |
| Documentation | 15 | Clear instructions, troubleshooting guide |

**Total: 100 points**

For additional details, refer to the comprehensive [INSTRUCTOR_GUIDE.md](INSTRUCTOR_GUIDE.md).

## Advanced Features

### Terraform Modules

The project uses modular Terraform code:

- **api-gateway module**: API Gateway configuration
- **dynamodb module**: DynamoDB table setup
- **lambda module**: Lambda function deployment
- **s3 module**: S3 bucket and website configuration
- **monitoring module**: CloudWatch alarms and logging

Benefits:
- Code reusability
- Better organization
- Easier maintenance
- Standardized configurations

### Security Scanning

Automated security scanning with Checkov:
- Infrastructure security validation
- Compliance checking
- Vulnerability detection
- SARIF report generation

### Monitoring and Alerting

CloudWatch monitoring includes:
- Lambda function error alarms
- Performance monitoring
- API Gateway error tracking
- Log retention management

## Future Enhancements

### Planned Features

1. **Multi-Environment Support**:
   - Separate dev/staging/prod environments
   - Environment-specific configurations
   - Promotion workflows

2. **Enhanced Monitoring**:
   - CloudWatch dashboards
   - Application performance monitoring
   - Cost tracking and alerts

3. **Advanced Security**:
   - WAF integration
   - SSL/TLS certificates
   - Security headers configuration

4. **Backup and Recovery**:
   - Automated backups
   - Disaster recovery procedures
   - Cross-region replication

## Support

For issues and questions:
1. Check the troubleshooting section in the instructor guide
2. Review GitHub Actions logs
3. Verify AWS resource status
4. Create an issue in the repository

## License

This project is licensed under the MIT License - see the LICENSE file for details.
