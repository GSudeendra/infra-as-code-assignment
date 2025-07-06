# Instructor Guide - Milestone 3: CI/CD and Advanced Features

This guide provides step-by-step instructions for instructors to set up and evaluate the Milestone 3 implementation, which includes CI/CD automation, Terraform modules, and advanced features.

## Quick Setup for Evaluation

### Prerequisites
- AWS CLI configured with appropriate credentials
- GitHub account
- Terraform >= 1.5.0
- Python 3.9+ (for testing)

### Step 1: Fork and Clone the Repository

1. **Fork the Repository**
   - Go to the original repository
   - Click "Fork" to create your own copy
   - Note your GitHub username and repository name

2. **Clone Your Fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/infra-as-code-assignment.git
   cd infra-as-code-assignment
   ```

### Step 2: Update Configuration for Your Environment

1. **Update GitHub OIDC Configuration**
   
   Edit `remote-state/github-oidc.tf`:
   ```hcl
   # Change this line with your GitHub username and repository name
   "token.actions.githubusercontent.com:sub" = "repo:YOUR_USERNAME/YOUR_REPO_NAME:*"
   ```

2. **Update Project Name (Optional)**
   
   Edit `remote-state/variables.tf`:
   ```hcl
   variable "environment" {
     description = "Environment name"
     type        = string
     default     = "instructor-eval"  # Change to avoid conflicts
   }
   ```

### Step 3: Deploy Remote State Infrastructure

1. **Navigate to Remote State Directory**
   ```bash
   cd remote-state
   ```

2. **Initialize and Deploy**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Save Important Outputs**
   Note the following outputs for later use:
   - `s3_bucket_name`: S3 bucket for Terraform state
   - `dynamodb_table_name`: DynamoDB table for state locking
   - `github_actions_role_arn`: GitHub Actions IAM role ARN

### Step 4: Configure GitHub Repository Secrets

1. **Go to Repository Settings**
   - Navigate to your forked repository on GitHub
   - Go to Settings → Secrets and Variables → Actions

2. **Add Required Secret**
   - Click "New repository secret"
   - Name: `AWS_ROLE_ARN`
   - Value: The GitHub Actions role ARN from step 3

### Step 5: Update Backend Configuration

1. **Update Terraform Backend**
   
   Edit `terraform/backend.tf`:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "YOUR_S3_BUCKET_NAME"  # From step 3
       key            = "terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "YOUR_DYNAMODB_TABLE_NAME"  # From step 3
       encrypt        = true
     }
   }
   ```

### Step 6: Initialize Main Terraform Project

```bash
cd ../terraform
terraform init
# Answer "yes" when prompted to migrate state
```

### Step 7: Test the CI/CD Pipeline

1. **Push Changes to Trigger Workflow**
   ```bash
   git add .
   git commit -m "Initial setup for instructor evaluation"
   git push origin main
   ```

2. **Monitor GitHub Actions**
   - Go to Actions tab in your repository
   - Watch the "Deploy Infrastructure" workflow
   - Verify all jobs complete without errors

3. **Manual Workflow Trigger (Optional)**
   - Go to Actions → Deploy Infrastructure
   - Click "Run workflow"
   - Choose action: `plan`, `apply`, or `destroy`

## Evaluation Checklist

### ✅ GitHub Actions Workflow
- [ ] Workflow runs successfully on push to main
- [ ] Workflow runs successfully on pull requests
- [ ] Manual workflow dispatch works
- [ ] All jobs complete without errors
- [ ] Terraform formatting check passes
- [ ] TFLint validation passes
- [ ] Security scanning with Checkov completes
- [ ] Infrastructure tests pass

### ✅ Terraform Modules
- [ ] Code is organized into reusable modules
- [ ] Custom monitoring module is implemented
- [ ] Modules have proper variables and outputs
- [ ] Main configuration uses modules effectively

### ✅ Infrastructure Deployment
- [ ] Remote state is configured correctly
- [ ] All AWS resources are created successfully
- [ ] API Gateway endpoints are accessible
- [ ] Lambda functions are deployed and working
- [ ] S3 bucket is configured for website hosting
- [ ] DynamoDB table is created with correct settings

### ✅ Security and Best Practices
- [ ] OIDC authentication is configured
- [ ] Least privilege IAM policies are implemented
- [ ] Security scanning identifies no critical issues
- [ ] Resources are properly tagged
- [ ] Cost optimization practices are followed

### ✅ Testing and Validation
- [ ] Infrastructure tests validate all components
- [ ] Application functionality tests pass
- [ ] Tests run automatically in CI/CD pipeline
- [ ] Test coverage includes security validation

### ✅ Documentation
- [ ] README is updated with comprehensive instructions
- [ ] Instructor guide is provided
- [ ] Deployment and destruction procedures are documented
- [ ] Troubleshooting information is included

## Testing the Application

### 1. Test User Registration
```bash
# Get API Gateway URL from Terraform outputs
API_URL=$(cd terraform && terraform output -raw api_gateway_url)

# Test user registration
curl -X POST "${API_URL}/register?userId=test_user_123"
```

### 2. Test User Verification
```bash
# Test verification for registered user
curl "${API_URL}/?userId=test_user_123"

# Test verification for non-registered user
curl "${API_URL}/?userId=nonexistent_user"
```

### 3. Run Automated Tests
```bash
cd tests
pip install -r requirements.txt
python -m pytest -v
```

## Infrastructure Destruction

### Automated Destruction
1. **Via GitHub Actions**
   - Go to Actions → Deploy Infrastructure
   - Click "Run workflow"
   - Select "destroy" action
   - Run workflow

### Manual Destruction
```bash
cd terraform
terraform destroy

cd ../remote-state
terraform destroy
```

## Troubleshooting Common Issues

### Issue: "Access Denied" Errors
**Solution**: 
- Verify AWS credentials are configured correctly
- Check that the GitHub Actions role ARN is set in repository secrets
- Ensure the OIDC configuration allows your repository

### Issue: "Bucket Already Exists" Errors
**Solution**:
- Update the `environment` variable in `remote-state/variables.tf` to something unique
- Use a different project name to avoid conflicts

### Issue: State Lock Errors
**Solution**:
- Ensure DynamoDB table exists and is accessible
- Check that the table name in backend configuration is correct
- Verify AWS credentials have DynamoDB permissions

### Issue: GitHub Actions Failures
**Solution**:
- Check the Actions tab for detailed error messages
- Verify all required secrets are configured
- Ensure the workflow file syntax is correct

### Issue: Terraform Module Errors
**Solution**:
- Run `terraform validate` to check configuration
- Ensure all required variables are provided
- Check module source paths are correct

## Advanced Evaluation

### Code Quality Assessment
- Review Terraform code formatting and structure
- Check for proper use of variables and outputs
- Evaluate module design and reusability
- Assess security best practices implementation

### CI/CD Pipeline Assessment
- Evaluate workflow design and job organization
- Check for proper error handling and notifications
- Assess security scanning integration
- Review testing strategy and coverage

### Infrastructure Design Assessment
- Evaluate resource organization and naming
- Check for cost optimization practices
- Assess monitoring and alerting setup
- Review security configurations

## Support and Resources

### Documentation
- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Tools Used
- **Terraform**: Infrastructure as Code
- **GitHub Actions**: CI/CD Pipeline
- **TFLint**: Terraform Linting
- **Checkov**: Security Scanning
- **Pytest**: Testing Framework
- **Boto3**: AWS SDK for Python

### Contact
For questions or issues during evaluation:
1. Check the troubleshooting section above
2. Review GitHub Actions logs for detailed error information
3. Verify AWS resource status in the AWS Console
4. Create an issue in the repository for persistent problems

## Conclusion

This Milestone 3 implementation demonstrates advanced Infrastructure as Code practices including:
- Automated CI/CD pipelines with GitHub Actions
- Modular Terraform code organization
- Security scanning and validation
- Comprehensive testing strategies
- OIDC authentication for secure AWS access
- Monitoring and alerting capabilities

The project showcases real-world DevOps practices and provides a solid foundation for production-ready infrastructure deployment. 