# Instructor Guide

This guide provides instructions for instructors to set up, test, and evaluate the Infrastructure as Code implementation.

## 🚀 Quick Setup

### Prerequisites
- AWS CLI configured with appropriate credentials
- GitHub account
- Terraform >= 1.5.0
- Python 3.9+ (for testing)

### Step 1: Fork and Clone
```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/infra-as-code-assignment.git
cd infra-as-code-assignment
```

### Step 2: Run Automated Setup
```bash
# Make the script executable and run it
chmod +x scripts/setup-instructor.sh
./scripts/setup-instructor.sh
```

The script will:
- ✅ Check all prerequisites
- ✅ Configure GitHub OIDC for your repository
- ✅ Deploy remote state infrastructure
- ✅ Update backend configuration
- ✅ Test the setup

### Step 3: Configure GitHub Variables
1. Go to your repository → Settings → Secrets and Variables → Actions → Variables
2. Add the following repository variables:
   - `AWS_ACCOUNT_ID`: Your AWS account ID
   - `S3_BUCKET_PREFIX`: Prefix for the S3 bucket (e.g., "iac-demo")
   - `DYNAMODB_TABLE_PREFIX`: Prefix for the DynamoDB table (e.g., "iac-demo") 
   - `AWS_REGION`: Your AWS region (optional, defaults to us-east-1)

The workflow will automatically compute the full resource names using your GitHub username and repository name.

## 🧪 Evaluation Process

### Infrastructure Deployment

#### Option A: Using GitHub Actions (Recommended)
- Push to the repository to trigger workflow
- Or manually run the "deploy" workflow from the Actions tab

#### Option B: Using Deployment Script
```bash
# Execute the deployment script from the root directory
./deploy
```

#### Option C: Manual Deployment

1. **Deploy Remote State**
   ```bash
   cd infra/backend
   terraform init
   terraform apply
   ```

2. **Deploy Main Infrastructure**
   ```bash
   cd ../infra
   terraform init \
     -backend-config="bucket=YOUR_S3_BUCKET" \
     -backend-config="dynamodb_table=YOUR_DYNAMODB_TABLE"
   terraform apply
   ```

### Testing the Deployment

#### Option A: Using Test Script (Recommended)
```bash
# Run all tests with the test script
./test
```

#### Option B: Manual Test Setup
```bash
cd tests
python -m venv test-env
source test-env/bin/activate  # On Windows: test-env\Scripts\activate
pip install -r requirements.txt
pytest -v
```

#### Manual API Testing

Use the API Gateway URL from the Terraform outputs:

```bash
# Test user registration
curl -X PUT "https://[API_URL]/register?userId=testuser123"

# Test user verification
curl "https://[API_URL]/?userId=testuser123"

# Or use the provided test script
scripts/test-user-system.sh [API_URL]
```

### Grading Checklist

- [ ] **GitHub Actions Workflow**
  - [ ] CI/CD pipeline passes
  - [ ] Security scanning implemented
  - [ ] TFLint validation runs

- [ ] **Infrastructure**
  - [ ] Remote state properly configured
  - [ ] All resources deploy without errors
  - [ ] API Gateway responds correctly
  - [ ] Lambda functions execute properly
  - [ ] DynamoDB stores user data
  - [ ] S3 hosts static content

- [ ] **Security**
  - [ ] OIDC authentication configured
  - [ ] Least privilege IAM policies
  - [ ] Resource encryption enabled

- [ ] **Testing**
  - [ ] All tests pass
  - [ ] Test coverage adequate

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section in README.md
2. Review GitHub Actions logs for error details
3. Verify AWS resource status in AWS Console
4. Run the setup script again if needed

## 🧹 Clean Up

After evaluation, ensure all resources are cleaned up:

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
cd infra
terraform destroy

# Clean up remote state infrastructure
cd ../infra/backend
terraform destroy
```

## 🎉 Success Criteria

The project is successfully implemented when:
- ✅ All GitHub Actions jobs pass
- ✅ Infrastructure deploys without errors
- ✅ API responds to requests
- ✅ Security scanning passes
- ✅ Tests run successfully
- ✅ Cleanup works properly
