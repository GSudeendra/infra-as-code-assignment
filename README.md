# Infrastructure as Code Assignment - Milestone 3

This repository contains the implementation of a serverless user registration and verification system using AWS services and Terraform, now enhanced with CI/CD automation, advanced Terraform modules, and comprehensive testing.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Milestone 3 Features](#milestone-3-features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Deployment Instructions](#deployment-instructions)
  - [Setting up Remote State](#setting-up-remote-state)
  - [Configuring GitHub Actions](#configuring-github-actions)
  - [Deploying the Main Infrastructure](#deploying-the-main-infrastructure)
- [CI/CD Pipeline](#cicd-pipeline)
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

2. **Lambda Functions**:
   - `register-user`: Handles user registration
   - `verify-user`: Validates user existence and returns appropriate HTML content

3. **DynamoDB**:
   - Stores user registration data
   - Uses PAY_PER_REQUEST billing mode for cost optimization

4. **S3 Bucket**:
   - Hosts static HTML content (index.html and error.html)
   - Serves success/error pages for user verification

5. **CloudWatch Monitoring**:
   - Log groups for Lambda functions
   - Alarms for errors and performance metrics
   - API Gateway monitoring

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

### Setting up Remote State

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

### Configuring GitHub Actions

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

For instructors evaluating this assignment, please refer to the comprehensive [INSTRUCTOR_GUIDE.md](INSTRUCTOR_GUIDE.md) which includes:

- Step-by-step setup instructions
- Evaluation checklist
- Testing procedures
- Troubleshooting guide
- Advanced assessment criteria

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
