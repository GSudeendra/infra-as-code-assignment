import requests
import pytest
import json
import time

class TestUserManagementAPI:
    """Test suite for the User Management API endpoints"""
    
    def test_user_registration_success(self, api_gateway_url: str, test_user_id: str):
        """Test successful user registration with valid userId"""
        response = requests.post(f"{api_gateway_url}/register?userId={test_user_id}")
        
        assert response.status_code == 200
        data = response.json()
        assert "success" in data.get("message", "").lower()
        assert data.get("userId") == test_user_id
        assert "timestamp" in data
    
    def test_user_registration_missing_userid_parameter(self, api_gateway_url: str):
        """Test user registration with missing userId parameter"""
        response = requests.post(f"{api_gateway_url}/register")
        
        assert response.status_code == 400
        data = response.json()
        assert "error" in data
        assert "missing" in data["error"].lower()
    
    def test_user_registration_empty_userid_value(self, api_gateway_url: str):
        """Test user registration with empty userId value"""
        response = requests.post(f"{api_gateway_url}/register?userId=")
        
        assert response.status_code == 400
        data = response.json()
        assert "error" in data
        assert "empty" in data["error"].lower()
    
    def test_user_verification_success_for_registered_user(self, api_gateway_url: str, test_user_id: str):
        """Test successful verification of a registered user"""
        # First register the user
        register_response = requests.post(f"{api_gateway_url}/register?userId={test_user_id}")
        assert register_response.status_code == 200
        
        # Then verify the user
        verify_response = requests.get(f"{api_gateway_url}/?userId={test_user_id}")
        
        assert verify_response.status_code == 200
        assert "text/html" in verify_response.headers.get("content-type", "")
        assert "Welcome" in verify_response.text
        assert "successful" in verify_response.text
    
    def test_user_verification_failure_for_unregistered_user(self, api_gateway_url: str):
        """Test verification failure for a non-registered user"""
        non_existent_user = f"nonexistent_{int(time.time())}"
        response = requests.get(f"{api_gateway_url}/?userId={non_existent_user}")
        
        assert response.status_code == 200
        assert "text/html" in response.headers.get("content-type", "")
        assert "Error" in response.text or "Access Denied" in response.text
        assert "failed" in response.text.lower()
    
    def test_user_verification_missing_userid_parameter(self, api_gateway_url: str):
        """Test user verification with missing userId parameter"""
        response = requests.get(f"{api_gateway_url}/")
        
        assert response.status_code == 400
        data = response.json()
        assert "error" in data
        assert "missing" in data["error"].lower()
    
    def test_user_verification_empty_userid_value(self, api_gateway_url: str):
        """Test user verification with empty userId value"""
        response = requests.get(f"{api_gateway_url}/?userId=")
        
        assert response.status_code == 400
        data = response.json()
        assert "error" in data
        assert "empty" in data["error"].lower()
    
    def test_user_registration_idempotency(self, api_gateway_url: str):
        """Test that registering the same user multiple times is idempotent"""
        # Use a unique user ID for this test
        idempotent_user_id = f"idempotent_test_{int(time.time())}"
        
        # Register user first time
        response1 = requests.post(f"{api_gateway_url}/register?userId={idempotent_user_id}")
        assert response1.status_code == 200
        
        # Register same user second time
        response2 = requests.post(f"{api_gateway_url}/register?userId={idempotent_user_id}")
        assert response2.status_code == 200
        
        # First should return success, second should indicate already registered
        assert "success" in response1.json().get("message", "").lower()
        assert "already registered" in response2.json().get("message", "").lower()
    
    def test_user_verification_independent_test_case(self, api_gateway_url: str):
        """Test user verification as an independent test case (creates its own user)"""
        # Create a new unique user for this test
        independent_test_user = f"independent_test_{int(time.time())}"
        
        # Register the user
        register_response = requests.post(f"{api_gateway_url}/register?userId={independent_test_user}")
        assert register_response.status_code == 200
        
        # Verify the user
        verify_response = requests.get(f"{api_gateway_url}/?userId={independent_test_user}")
        assert verify_response.status_code == 200
        assert "Welcome" in verify_response.text
    
    def test_api_gateway_endpoint_health_check(self, api_gateway_url: str):
        """Test that API Gateway endpoints are responding correctly"""
        # Test register endpoint without userId (should return 400)
        register_response = requests.post(f"{api_gateway_url}/register")
        assert register_response.status_code == 400
        
        # Test verify endpoint without userId (should return 400)
        verify_response = requests.get(f"{api_gateway_url}/")
        assert verify_response.status_code == 400 