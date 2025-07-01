# Infrastructure as Code Assignment

This project implements a simple serverless API using AWS Lambda and API Gateway, deployed using Terraform.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed (>= 1.0.0)
- Python 3.11 or later

## How to Deploy

1. Initialize Terraform:
```bash
cd terraform
terraform init
```

2. Review the planned changes:
```bash
terraform plan
```

3. Apply the infrastructure:
```bash
terraform apply
```

4. After successful deployment, you'll see the API Gateway URL in the outputs.

## How to Test

1. Install test dependencies:
```bash
cd tests
pip install -r requirements.txt
```

2. Run the tests:
```bash
./run.sh
```

The tests will verify that the API Gateway endpoint returns "Hello world" as expected.

## How to Access CloudWatch Logs

1. Log into AWS Console
2. Navigate to CloudWatch > Log Groups
3. Find the log group named `/aws/lambda/[environment]-hello-world-lambda`

## How to Destroy

To destroy all resources:

```bash
cd terraform
terraform destroy
```

Note: This will remove all resources created by this project, including:
- Lambda function
- API Gateway
- IAM roles and policies
- CloudWatch Log groups
