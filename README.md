# AWS Serverless User Management – Infrastructure as Code

## Overview
A production-grade, serverless user management system on AWS, fully automated with Terraform and GitHub Actions. Features secure OIDC authentication, modular infrastructure, and CI/CD pipelines for deployment, testing, and teardown.

---

## Architecture
- **API Gateway**: Exposes REST endpoints for user registration and verification
- **Lambda Functions**: Stateless compute for business logic
- **DynamoDB**: User data storage
- **S3**: Static HTML hosting for user feedback
- **CloudWatch/KMS**: Monitoring and secure log encryption
- **GitHub Actions OIDC**: Secure, short-lived AWS credentials for CI/CD

---

## Prerequisites
- AWS account with admin access
- AWS CLI installed and configured
- Terraform >= 1.5.0
- Python 3.8+ (for tests)
- GitHub repository (forked or cloned)

---

## Quick Start: One-Time Bootstrap & OIDC Setup

> **You must bootstrap the backend and OIDC role locally before using CI/CD.**

1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd <your-repo-directory>
   ```
2. **Run the backend bootstrap script:**
   ```sh
   chmod +x scripts/utilities/bootstrap_backend.sh
   ./scripts/utilities/bootstrap_backend.sh
   ```
   - This creates the S3 bucket, DynamoDB table, and checks for the OIDC IAM role.
3. **Provision the OIDC IAM role and backend infra:**
   ```sh
   cd infra/backend
   terraform init
   terraform apply
   ```
   - This creates the IAM role for GitHub Actions and remote state infra.
4. **Set required GitHub repository variables:**
   - Go to **GitHub → Settings → Secrets and variables → Actions → Variables**
   - Add:
     | Name                        | Example Value                  | Purpose                      |
     |-----------------------------|-------------------------------|------------------------------|
     | `AWS_ACCOUNT_ID`            | `123456789012`                | Your AWS account number      |
     | `AWS_REGION`                | `us-east-1`                   | AWS region                   |
     | `TERRAFORM_EXECUTION_ROLE_NAME` | `iac-github-actions-role-dev` | OIDC IAM role name           |

---

## CI/CD Usage (GitHub Actions)

- **Deploy Infrastructure:**
  - Trigger the `deploy-infrastructure-pipeline` workflow (manually or on push).
  - The workflow will:
    - Assume the OIDC role
    - Run Terraform to deploy all infrastructure
    - Run automated tests
- **Destroy Infrastructure:**
  - Trigger the `destroy-infrastructure-pipeline` workflow.
  - The workflow will:
    - Assume the OIDC role
    - Run Terraform destroy to remove all infrastructure
- **Bootstrap/Destroy Backend:**
  - Use the `bootstrap-backend` or `destroy-backend` workflow for one-time backend setup or teardown.

### Visual Workflow
```mermaid
graph TD
    A[Run bootstrap_backend.sh (local, one time)] --> B[terraform apply in infra/backend (local, one time)]
    B --> C[Set GitHub repo variables (one time)]
    C --> D[Use GitHub Actions workflows (deploy, destroy, test)]
```

---

## Manual Terraform Usage (Advanced)

- **Deploy main infrastructure:**
  ```sh
  cd infra
  terraform init
  terraform apply
  ```
- **Destroy main infrastructure:**
  ```sh
  terraform destroy
  ```
- **Destroy backend (after all else is destroyed):**
  ```sh
  cd backend
  terraform destroy
  ```

---

## Testing

- **Automated tests:**
  ```sh
  cd tests
  python3 -m venv .venv
  source .venv/bin/activate
  pip install -r requirements.txt
  pytest -v
  ```
- **Manual API testing:**
  - Register user:
    ```sh
    curl -X POST "<API_GATEWAY_URL>/register?userId=testuser"
    ```
  - Verify user:
    ```sh
    curl "<API_GATEWAY_URL>/?userId=testuser"
    ```

---

## Destruction & Cleanup
- **Via GitHub Actions:** Use the `destroy-infrastructure-pipeline` and `destroy-backend` workflows.
- **Manual:** See above for Terraform commands. Empty S3 buckets before destroying if needed:
  ```sh
  aws s3 rm s3://<your-bucket> --recursive
  ```

---

## Troubleshooting
- **OIDC errors:** Ensure the IAM role and trust policy match your repo and OIDC provider.
- **Permission errors:** Update the IAM policy in `infra/backend/github-oidc.tf` as needed.
- **Resource already exists:** Use `terraform import` to bring existing resources into state.
- **Workflow failures:** Check GitHub Actions logs for details.

---

## Project Structure
```
├── infra/                  # Terraform code (main, backend, modules)
├── src/                    # Lambda source code (Python)
├── html/                   # Static HTML for S3
├── tests/                  # Automated test suite
├── scripts/                # Deployment, utility, and test scripts
├── .github/workflows/      # GitHub Actions pipelines
└── README.md               # This file
```

---

## Contributing & Support
- Fork, branch, and open PRs for improvements.
- For help, open an issue or contact the maintainer.

---

**All resources are created in `us-east-1`. Resource names are unique and follow project conventions.**

---

## Post-Deployment Verification Checklist
After deploying the infrastructure (locally or via GitHub Actions), verify the following before destruction:

### A. API Gateway Endpoints
- **Get the API Gateway URL:**
  ```sh
  terraform output -raw api_gateway_url
  ```
- **Register a user:**
  ```sh
  curl -X POST "<API_GATEWAY_URL>/register?userId=testuser"
  ```
  - Expected: JSON response confirming registration.
- **Verify a registered user:**
  ```sh
  curl "<API_GATEWAY_URL>/?userId=testuser"
  ```
  - Expected: Returns the HTML content of index.html (user verified).
- **Verify a non-existent user:**
  ```sh
  curl "<API_GATEWAY_URL>/?userId=nouser"
  ```
  - Expected: Returns the HTML content of error.html (verification failed).

### B. S3 Bucket
- Go to AWS S3 Console (us-east-1 region).
- Search for your bucket (e.g., static-content-<env>-<random>).
- Check that both index.html and error.html are present.
- (Optional): Open the S3 static website endpoint in your browser to view the HTML files.

### C. DynamoDB Table
- Go to AWS DynamoDB Console (us-east-1 region).
- Find your table (e.g., users-<env>-<random>).
- Check that registered users appear as items in the table.

### D. Lambda and CloudWatch Logs
- Go to AWS Lambda Console (us-east-1 region).
- Check that both register_user and verify_user functions exist.
- Go to CloudWatch Logs Console.
- Check log groups /aws/lambda/register_user and /aws/lambda/verify_user for recent activity and errors.

### E. Automated Tests
- Run the automated test suite:
  ```sh
  cd tests
  pytest -v
  ```
  - Expected: All tests should pass.

---

## CI/CD & GitHub Actions

Before running any GitHub Actions workflows, set these variables in your repo:

| Variable Name                  | Example Value                  | Purpose                                 |
|------------------------------- |-------------------------------|-----------------------------------------|
| `AWS_ACCOUNT_ID`               | `160071257600`                 | Your AWS account number                 |
| `AWS_REGION`                   | `us-east-1`                    | AWS region for all resources            |
| `TERRAFORM_EXECUTION_ROLE_NAME`| `iac-github-actions-role-dev`  | IAM role name for OIDC (must match infra)|

- After setting these, you can trigger the deploy and destroy workflows from the GitHub Actions tab as described above.
