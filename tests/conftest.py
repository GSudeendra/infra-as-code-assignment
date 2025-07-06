import pytest
import os
import time
from typing import Optional

@pytest.fixture(scope="session")
def api_gateway_url() -> str:
    """Get API Gateway URL from environment or use default"""
    return os.environ.get("API_GATEWAY_URL", "https://abc123.execute-api.us-east-1.amazonaws.com")

@pytest.fixture(scope="session")
def test_user_id() -> str:
    """Generate a unique user ID for testing"""
    return f"testuser_{int(time.time())}" 