# Infra as Code – AWS Serverless User Management

## Project Overview

This project implements a serverless user registration and verification system on AWS using Infrastructure as Code (IaC) with Terraform. The solution leverages API Gateway, Lambda, DynamoDB, and S3, and is fully automated with CI/CD via GitHub Actions.

- **API Gateway**: Exposes `/register` and `/` endpoints.
- **Lambda Functions**: Handle user registration and verification.
- **DynamoDB**: Stores user data.
- **S3**: Hosts static HTML pages for success/error responses.
- **CI/CD**: Automated deploy, test, lint, and destroy via GitHub Actions.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Deployment Instructions](#deployment-instructions)
- [Testing Instructions](#testing-instructions)
- [Destruction Instructions](#destruction-instructions)
- [CI/CD & GitHub Actions](#cicd--github-actions)
- [Design Decisions](#design-decisions)
- [Module Usage](#module-usage)
- [Secrets, Variables & Setup](#secrets-variables--setup)
- [Milestone Checklist](#milestone-checklist)

---

## Architecture

![Architecture Diagram](./docs/architecture-diagram.png)

- **API Gateway** routes requests to Lambda functions.
- **Lambda** functions interact with DynamoDB and S3.
- **DynamoDB** stores user records.
- **S3** serves static HTML for verification results.

---

## Project Structure

```
├── infra/                  # All Terraform code
│   ├── main.tf             # Main infrastructure
│   ├── backend/            # Remote state & OIDC setup
│   └── modules/            # Custom Terraform modules
├── src/                    # Lambda source code (Python)
├── html/                   # Static HTML files for S3
├── tests/                  # Automated test suite (pytest)
├── scripts/                # Helper scripts for deployment, testing, etc.
├── .github/workflows/      # GitHub Actions CI/CD pipelines
└── README.md               # This file
```

---

## Deployment Instructions

### **Milestone 1: Local Deployment**

1. **Clone the repository**  
   ```sh
   git clone <your-repo-url>
   cd <your-repo>
   ```

2. **Initialize and apply Terraform**  
   ```sh
   cd infra
   terraform init
   terraform apply
   ```

3. **Get the API Gateway URL**  
   ```sh
   terraform output api_gateway_url
   ```

---

### **Milestone 2: Remote State & Full Infra**

1. **Deploy remote state backend**  
   ```sh
   cd infra/backend
   terraform init
   terraform apply
   ```

2. **Deploy main infrastructure (using remote state)**  
   ```sh
   cd ../
   terraform init \
     -backend-config="bucket=<your-s3-bucket>" \
     -backend-config="dynamodb_table=<your-dynamodb-table>" \
     -backend-config="region=<your-region>"
   terraform apply
   ```

3. **Upload HTML files to S3**  
   ```sh
   aws s3 cp html/index.html s3://<your-bucket>/
   aws s3 cp html/error.html s3://<your-bucket>/
   ```

---

### **Milestone 3: CI/CD Deployment (Recommended)**

1. **Fork this repository** to your own GitHub account.
2. **Configure GitHub repository variables**:
   - `AWS_ACCOUNT_ID`
   - `AWS_REGION`
3. **Ensure OIDC/IAM role is set up** (see [Secrets, Variables & Setup](#secrets-variables--setup)).
4. **Run the deploy workflow**:
   - Go to the "Actions" tab in GitHub.
   - Select `deploy-infrastructure-pipeline` and click "Run workflow".
5. **Monitor the workflow** for completion and outputs.

---

## Testing Instructions

### **Automated Tests**

1. **Set up Python environment**  
   ```sh
   cd tests
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Run tests**  
   ```sh
   pytest -v
   ```

### **Manual API Testing**

- **Register a user**  
  ```sh
  curl -X PUT "<API_GATEWAY_URL>/register?userId=testuser"
  ```
- **Verify a user**  
  ```sh
  curl "<API_GATEWAY_URL>/?userId=testuser"
  ```

- **Check S3 for HTML files**  
  - Visit the S3 bucket website endpoint to view `index.html` and `error.html`.

---

## Post-Deployment Verification Checklist

After deploying the infrastructure (locally or via GitHub Actions), verify the following before destruction:

### **A. API Gateway Endpoints**

- **Get the API Gateway URL:**
  ```sh
  terraform output -raw api_gateway_url
  ```
- **Register a user:**
  ```sh
  curl -X POST "<API_GATEWAY_URL>/register?userId=testuser"
  ```
  - **Expected:** JSON response confirming registration.

- **Verify a registered user:**
  ```sh
  curl "<API_GATEWAY_URL>/?userId=testuser"
  ```
  - **Expected:** Returns the HTML content of `index.html` (user verified).

- **Verify a non-existent user:**
  ```sh
  curl "<API_GATEWAY_URL>/?userId=nouser"
  ```
  - **Expected:** Returns the HTML content of `error.html` (verification failed).

---

### **B. S3 Bucket**

- **Go to AWS S3 Console** (`us-east-1` region).
- **Search for your bucket** (e.g., `static-content-<env>-<random>`).
- **Check that both `index.html` and `error.html` are present.**
- **(Optional):** Open the S3 static website endpoint in your browser to view the HTML files.

---

### **C. DynamoDB Table**

- **Go to AWS DynamoDB Console** (`us-east-1` region).
- **Find your table** (e.g., `users-<env>-<random>`).
- **Check that registered users appear as items in the table.**

---

### **D. Lambda and CloudWatch Logs**

- **Go to AWS Lambda Console** (`us-east-1` region).
- **Check that both `register_user` and `verify_user` functions exist.**
- **Go to CloudWatch Logs Console**.
- **Check log groups `/aws/lambda/register_user` and `/aws/lambda/verify_user` for recent activity and errors.**

---

### **E. Automated Tests**

- **Run the automated test suite:**
  ```sh
  cd tests
  pytest -v
  ```
  - **Expected:** All tests should pass.

---

## Destruction Instructions

### **Via GitHub Actions (Milestone 3)**

1. Go to the "Actions" tab.
2. Select `destroy-infrastructure-pipeline` and click "Run workflow".
3. Confirm all resources are deleted in AWS Console.

### **Manual Destruction**

1. **Destroy main infrastructure**  
   ```sh
   cd infra
   terraform destroy
   ```
2. **Destroy remote state backend**  
   ```sh
   cd backend
   terraform destroy
   ```
3. **If S3 bucket is not empty, empty it first**  
   ```sh
   aws s3 rm s3://<your-bucket> --recursive
   ```

---

## CI/CD & GitHub Actions

- **Workflows**: `.github/workflows/deploy.yaml` and `.github/workflows/destroy.yaml`
- **Features**:
  - Deploys remote state and main infra
  - Runs formatting, linting, security checks, and tests
  - Generates documentation
  - Destroys infra in correct order
- **Setup**:
  - Requires OIDC-enabled IAM role in AWS
  - Set `AWS_ACCOUNT_ID` and `AWS_REGION` as repository variables
- **Troubleshooting**:
  - Check workflow logs for errors
  - Ensure IAM role trust policy allows your repo
- **Note:** The deploy workflow will automatically call the API Gateway endpoints and run the automated test suite after infrastructure is deployed. This ensures that your API is live and functional. You can view test results and API call outputs in the Actions tab under the deploy workflow run.

---

## Design Decisions

- **Modular Terraform**: All resources are organized into modules for clarity and reusability.
- **Remote State**: Uses S3 + DynamoDB for safe, collaborative state management.
- **Least Privilege IAM**: All roles and policies are tightly scoped.
- **CI/CD**: All deployments, tests, and checks are automated for reliability and reproducibility.
- **Public Modules**: Used official S3 module for best practices; custom modules for learning and flexibility.

---

## Module Usage

- **Custom Modules**: API Gateway, Lambda, DynamoDB, Monitoring.
- **Public Modules**: [terraform-aws-modules/s3-bucket/aws](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest) (if used).
- **Why**: Custom modules for learning and control; public modules for reliability and community best practices.

---

## Secrets, Variables & Setup

- **GitHub Variables**:
  - `AWS_ACCOUNT_ID`: Your AWS account number
  - `AWS_REGION`: AWS region to deploy to
- **OIDC Setup**:
  - Ensure an IAM role exists with trust policy for GitHub OIDC
  - Role name: `github-oidc-<owner>-<repo>`
- **How to Fork and Run**:
  1. Fork repo
  2. Set variables in GitHub repo settings
  3. Run workflows from Actions tab

---

## Milestone Checklist

| Requirement                           | Milestone 1   | Milestone 2          | Milestone 3                 |
| ------------------------------------- | ------------- | -------------------- | --------------------------- |
| Project overview                      | ✅             | ✅                    | ✅                           |
| Infrastructure deployment steps       | ✅             | ✅ (remote state too) | ✅ (via CI/CD)               |
| Infrastructure destruction steps      | ✅             | ✅                    | ✅ (via GitHub Actions)      |
| Test setup & how to run tests         | ✅ (1 test)    | ✅ (6+ tests)         | ✅ (integrated in CI/CD)     |
| Clear outputs (API Gateway URL, etc.) | ✅             | ✅                    | ✅                           |
| Module usage explanation              | ❌ Optional    | ✅                    | ✅                           |
| GitHub Actions setup                  | ❌             | ❌                    | ✅ (secrets, OIDC, triggers) |
| Design decisions                      | ✅ Recommended | ✅ Recommended        | ✅ Required                  |
| Project structure overview            | ✅ Recommended | ✅ Recommended        | ✅ Recommended               |

---

## Questions?

If you have any questions or issues, please open an issue or contact the instructor.

---

**_Good luck, and happy automating!_**
# Force trigger Wed Jul 16 05:18:41 IST 2025
