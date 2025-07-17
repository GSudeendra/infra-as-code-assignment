import pytest
import os
import time
from typing import Optional
import subprocess
import json

def load_infra_output(key):
    try:
        with open(os.path.join(os.path.dirname(__file__), '../infra/infra_outputs.json')) as f:
            outputs = json.load(f)
        return outputs[key]["value"]
    except Exception:
        return os.environ.get(key.upper())

def get_api_gateway_url():
    url = load_infra_output('api_gateway_url')
    if url:
        return url
    # fallback to terraform output if needed
    result = subprocess.run([
        'terraform', 'output', '-raw', 'api_gateway_url'
    ], capture_output=True, text=True, cwd='../infra')
    return result.stdout.strip().replace('%', '')

@pytest.fixture(scope="session")
def api_gateway_url():
    return get_api_gateway_url()

@pytest.fixture(scope="session")
def s3_bucket_name():
    return load_infra_output('s3_bucket_name')

@pytest.fixture(scope="session")
def dynamodb_table_name():
    return load_infra_output('dynamodb_table_name')

@pytest.fixture(scope="session")
def api_gateway_id():
    return load_infra_output('api_gateway_id')

@pytest.fixture(scope="session")
def test_user_id() -> str:
    """Generate a unique user ID for testing"""
    return f"testuser_{int(time.time())}" 