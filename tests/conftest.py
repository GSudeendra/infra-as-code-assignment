import pytest
import os
import time
from typing import Optional
import subprocess

def get_api_gateway_url():
    result = subprocess.run([
        'terraform', 'output', '-raw', 'api_gateway_url'
    ], capture_output=True, text=True, cwd='../terraform')
    url = result.stdout.strip().replace('%', '')
    return url

@pytest.fixture(scope="session")
def api_gateway_url():
    return get_api_gateway_url()

@pytest.fixture(scope="session")
def test_user_id() -> str:
    """Generate a unique user ID for testing"""
    return f"testuser_{int(time.time())}" 