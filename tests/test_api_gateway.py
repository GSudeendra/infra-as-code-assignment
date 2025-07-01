import json
import os
from src.hello_world import lambda_handler

API_GATEWAY_URL = os.environ.get("API_GATEWAY_URL", "https://abc123.execute-api.us-east-1.amazonaws.com")

def test_hello_world():
    # Test the Lambda function directly
    response = lambda_handler({}, {})

    # Assert the response structure
    assert response['statusCode'] == 200
    assert response['body'] == "Hello world"
