import boto3
import requests
import json
import subprocess
import pytest
import time
from botocore.exceptions import ClientError

AWS_REGION = 'us-east-1'

class TestInfrastructure:
    """Test suite for infrastructure validation"""
    
    @classmethod
    def setup_class(cls):
        """Set up test fixtures before running tests."""
        cls.s3_client = boto3.client('s3', region_name=AWS_REGION)
        cls.dynamodb_client = boto3.client('dynamodb', region_name=AWS_REGION)
        cls.lambda_client = boto3.client('lambda', region_name=AWS_REGION)
        cls.apigateway_client = boto3.client('apigateway', region_name=AWS_REGION)
        
        # Get Terraform outputs
        try:
            result = subprocess.run(['terraform', 'output', '-json'], 
                                  capture_output=True, text=True, cwd='../terraform')
            if result.returncode == 0:
                cls.tf_outputs = json.loads(result.stdout)
            else:
                cls.tf_outputs = {}
        except Exception as e:
            print(f"Warning: Could not get Terraform outputs: {e}")
            cls.tf_outputs = {}
    
    def test_s3_bucket_exists(self):
        """Test that S3 bucket exists and is accessible."""
        bucket_name = self.tf_outputs.get('s3_bucket_name', {}).get('value')
        if not bucket_name:
            pytest.skip("S3 bucket name not found in Terraform outputs")
        
        try:
            response = self.s3_client.head_bucket(Bucket=bucket_name)
            assert response['ResponseMetadata']['HTTPStatusCode'] == 200
        except ClientError as e:
            pytest.fail(f"S3 bucket {bucket_name} does not exist or is not accessible: {e}")
    
    def test_s3_bucket_website_configuration(self):
        """Test that S3 bucket has website configuration."""
        bucket_name = self.tf_outputs.get('s3_bucket_name', {}).get('value')
        if not bucket_name:
            pytest.skip("S3 bucket name not found in Terraform outputs")
        
        try:
            response = self.s3_client.get_bucket_website(Bucket=bucket_name)
            assert 'IndexDocument' in response
            assert response['IndexDocument']['Suffix'] == 'index.html'
            assert 'ErrorDocument' in response
            assert response['ErrorDocument']['Key'] == 'error.html'
        except ClientError as e:
            pytest.fail(f"S3 bucket {bucket_name} website configuration not found: {e}")
    
    def test_s3_bucket_files_exist(self):
        """Test that required HTML files exist in S3 bucket."""
        bucket_name = self.tf_outputs.get('s3_bucket_name', {}).get('value')
        if not bucket_name:
            pytest.skip("S3 bucket name not found in Terraform outputs")
        
        required_files = ['index.html', 'error.html']
        
        for file_key in required_files:
            try:
                response = self.s3_client.head_object(Bucket=bucket_name, Key=file_key)
                assert response['ResponseMetadata']['HTTPStatusCode'] == 200
                assert response['ContentType'] == 'text/html'
            except ClientError as e:
                pytest.fail(f"File {file_key} not found in bucket {bucket_name}: {e}")
    
    def test_dynamodb_table_exists(self):
        """Test that DynamoDB table exists and is accessible."""
        table_name = self.tf_outputs.get('dynamodb_table_name', {}).get('value')
        if not table_name:
            pytest.skip("DynamoDB table name not found in Terraform outputs")
        
        try:
            response = self.dynamodb_client.describe_table(TableName=table_name)
            assert response['Table']['TableStatus'] == 'ACTIVE'
            assert response['Table']['BillingModeSummary']['BillingMode'] == 'PAY_PER_REQUEST'
        except ClientError as e:
            pytest.fail(f"DynamoDB table {table_name} does not exist or is not accessible: {e}")
    
    def test_lambda_functions_exist(self):
        """Test that Lambda functions exist and are accessible."""
        lambda_functions = ['register_user', 'verify_user']
        
        for function_name in lambda_functions:
            try:
                response = self.lambda_client.get_function(FunctionName=function_name)
                assert response['Configuration']['State'] == 'Active'
                assert response['Configuration']['Runtime'] == 'python3.9'
            except ClientError as e:
                pytest.fail(f"Lambda function {function_name} does not exist or is not accessible: {e}")
    
    def test_api_gateway_exists(self):
        """Test that API Gateway exists and is accessible."""
        api_id = self.tf_outputs.get('api_gateway_id', {}).get('value')
        if not api_id:
            pytest.skip("API Gateway ID not found in Terraform outputs")
        
        try:
            response = self.apigateway_client.get_rest_api(restApiId=api_id)
            assert response['name'] == 'user-management-api'
        except ClientError as e:
            pytest.fail(f"API Gateway {api_id} does not exist or is not accessible: {e}")
    
    def test_api_gateway_deployment(self):
        """Test that API Gateway has a deployment."""
        api_id = self.tf_outputs.get('api_gateway_id', {}).get('value')
        if not api_id:
            pytest.skip("API Gateway ID not found in Terraform outputs")
        
        try:
            response = self.apigateway_client.get_deployments(restApiId=api_id)
            assert len(response['items']) > 0
            # Check if there's at least one deployment
            deployments = [d for d in response['items'] if d['stageName'] == 'dev']
            assert len(deployments) > 0
        except ClientError as e:
            pytest.fail(f"API Gateway {api_id} deployment not found: {e}")
    
    def test_api_gateway_endpoints_accessible(self):
        """Test that API Gateway endpoints are accessible."""
        api_gateway_url = self.tf_outputs.get('api_gateway_url', {}).get('value')
        if not api_gateway_url:
            pytest.skip("API Gateway URL not found in Terraform outputs")
        
        # Test register endpoint
        try:
            response = requests.post(f"{api_gateway_url}/register?userId=test_user")
            # Should return 200 for valid request or 400 for missing parameters
            assert response.status_code in [200, 400]
        except requests.RequestException as e:
            pytest.fail(f"API Gateway register endpoint not accessible: {e}")
        
        # Test verify endpoint
        try:
            response = requests.get(f"{api_gateway_url}/?userId=test_user")
            # Should return 200 for valid request or 400 for missing parameters
            assert response.status_code in [200, 400]
        except requests.RequestException as e:
            pytest.fail(f"API Gateway verify endpoint not accessible: {e}")
    
    def test_s3_bucket_security(self):
        """Test S3 bucket security settings."""
        bucket_name = self.tf_outputs.get('s3_bucket_name', {}).get('value')
        if not bucket_name:
            pytest.skip("S3 bucket name not found in Terraform outputs")
        
        # Check bucket policy exists
        try:
            response = self.s3_client.get_bucket_policy(Bucket=bucket_name)
            assert 'Policy' in response
            
            # Parse policy and check for public read access
            policy = json.loads(response['Policy'])
            assert 'Statement' in policy
            
            # Look for public read statement
            public_read_found = False
            for statement in policy['Statement']:
                if (statement.get('Effect') == 'Allow' and 
                    statement.get('Principal') == '*' and 
                    's3:GetObject' in statement.get('Action', [])):
                    public_read_found = True
                    break
            
            assert public_read_found, "Public read access not configured correctly"
            
        except ClientError as e:
            pytest.fail(f"Failed to get bucket policy for {bucket_name}: {e}")
    
    def test_lambda_function_permissions(self):
        """Test that Lambda functions have necessary permissions."""
        lambda_functions = ['register_user', 'verify_user']
        iam_client = boto3.client('iam', region_name=AWS_REGION)
        for function_name in lambda_functions:
            try:
                # Get the Lambda function configuration to find the execution role
                response = self.lambda_client.get_function(FunctionName=function_name)
                role_arn = response['Configuration']['Role']
                role_name = role_arn.split('/')[-1]
                # Get the inline policies
                inline_policies = iam_client.list_role_policies(RoleName=role_name)['PolicyNames']
                dynamodb_permissions = False
                # Check inline policies
                for policy_name in inline_policies:
                    policy = iam_client.get_role_policy(RoleName=role_name, PolicyName=policy_name)
                    statements = policy['PolicyDocument'].get('Statement', [])
                    if not isinstance(statements, list):
                        statements = [statements]
                    for statement in statements:
                        actions = statement.get('Action', [])
                        if isinstance(actions, str):
                            actions = [actions]
                        if any('dynamodb:' in action for action in actions):
                            dynamodb_permissions = True
                            break
                # Check attached managed policies
                attached_policies = iam_client.list_attached_role_policies(RoleName=role_name)['AttachedPolicies']
                for attached in attached_policies:
                    policy_arn = attached['PolicyArn']
                    policy_version = iam_client.get_policy(PolicyArn=policy_arn)['Policy']['DefaultVersionId']
                    policy_doc = iam_client.get_policy_version(PolicyArn=policy_arn, VersionId=policy_version)['PolicyVersion']['Document']
                    statements = policy_doc.get('Statement', [])
                    if not isinstance(statements, list):
                        statements = [statements]
                    for statement in statements:
                        actions = statement.get('Action', [])
                        if isinstance(actions, str):
                            actions = [actions]
                        if any('dynamodb:' in action for action in actions):
                            dynamodb_permissions = True
                            break
                assert dynamodb_permissions, f"Lambda function {function_name} missing DynamoDB permissions"
            except ClientError as e:
                pytest.fail(f"Failed to check permissions for Lambda function {function_name}: {e}")
    
    def test_cloudwatch_log_groups_exist(self):
        """Test that CloudWatch log groups exist for Lambda functions."""
        log_client = boto3.client('logs', region_name=AWS_REGION)
        lambda_functions = ['register_user', 'verify_user']
        
        for function_name in lambda_functions:
            log_group_name = f"/aws/lambda/{function_name}"
            # Try to find the log group with retries
            max_retries = 3
            for attempt in range(max_retries):
                try:
                    response = log_client.describe_log_groups(logGroupNamePrefix=log_group_name)
                    if len(response['logGroups']) > 0:
                        # Found the log group
                        assert response['logGroups'][0]['logGroupName'] == log_group_name
                        break
                    else:
                        # Log group not found, try to invoke Lambda to trigger creation
                        if attempt == 0:  # Only invoke on first attempt
                            try:
                                self.lambda_client.invoke(
                                    FunctionName=function_name,
                                    Payload=b'{}',
                                    InvocationType='RequestResponse'
                                )
                                print(f"Invoked {function_name} to trigger log group creation")
                            except Exception as e:
                                print(f"Failed to invoke {function_name}: {e}")
                        
                        if attempt < max_retries - 1:
                            print(f"Log group {log_group_name} not found, retrying in 5 seconds... (attempt {attempt + 1}/{max_retries})")
                            time.sleep(5)
                        else:
                            # Last attempt failed, print available log groups for debugging
                            all_log_groups = log_client.describe_log_groups()
                            print(f"Available log groups: {[lg['logGroupName'] for lg in all_log_groups.get('logGroups', [])]}")
                            pytest.fail(f"CloudWatch log group {log_group_name} not found after {max_retries} attempts")
                except ClientError as e:
                    if attempt < max_retries - 1:
                        print(f"Error checking log group {log_group_name}, retrying in 5 seconds... (attempt {attempt + 1}/{max_retries})")
                        time.sleep(5)
                    else:
                        pytest.fail(f"CloudWatch log group {log_group_name} not found: {e}")
    
    def test_infrastructure_cost_optimization(self):
        """Test that infrastructure follows cost optimization practices."""
        # Check DynamoDB billing mode
        table_name = self.tf_outputs.get('dynamodb_table_name', {}).get('value')
        if table_name:
            try:
                response = self.dynamodb_client.describe_table(TableName=table_name)
                billing_mode = response['Table']['BillingModeSummary']['BillingMode']
                assert billing_mode == 'PAY_PER_REQUEST', "DynamoDB should use PAY_PER_REQUEST billing mode"
            except ClientError:
                pass  # Skip if table not found
        
        # Check Lambda timeout settings
        lambda_functions = ['register_user', 'verify_user']
        for function_name in lambda_functions:
            try:
                response = self.lambda_client.get_function(FunctionName=function_name)
                timeout = response['Configuration']['Timeout']
                assert timeout <= 30, f"Lambda function {function_name} timeout should be <= 30 seconds"
            except ClientError:
                pass  # Skip if function not found

if __name__ == "__main__":
    pytest.main([__file__, "-v"]) 