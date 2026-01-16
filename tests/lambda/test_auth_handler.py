"""
Unit tests for authentication Lambda handler
"""

import json
import pytest
from unittest.mock import Mock, patch, MagicMock
from botocore.exceptions import ClientError


# Mock environment variables before importing handler
@pytest.fixture(autouse=True)
def mock_env_vars(monkeypatch):
    """Mock environment variables for Lambda"""
    monkeypatch.setenv('USER_POOL_ID', 'us-west-2_TEST123')
    monkeypatch.setenv('CLIENT_ID', 'test-client-id-123')


# Import after mocking env vars
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../infrastructure/lambda'))
from auth_handler import (
    lambda_handler,
    handle_register,
    handle_login,
    handle_refresh,
    success_response,
    error_response
)


class TestLambdaHandler:
    """Test main Lambda handler routing"""

    def test_register_route(self):
        """Test routing to register handler"""
        event = {
            'httpMethod': 'POST',
            'path': '/auth/register',
            'body': json.dumps({
                'email': 'test@example.com',
                'password': 'SecurePass123!',
                'studyCode': 'test_study',
                'participantId': 'TEST001'
            })
        }

        with patch('auth_handler.handle_register') as mock_register:
            mock_register.return_value = {'statusCode': 200}
            result = lambda_handler(event, None)
            mock_register.assert_called_once()

    def test_login_route(self):
        """Test routing to login handler"""
        event = {
            'httpMethod': 'POST',
            'path': '/auth/login',
            'body': json.dumps({
                'email': 'test@example.com',
                'password': 'SecurePass123!'
            })
        }

        with patch('auth_handler.handle_login') as mock_login:
            mock_login.return_value = {'statusCode': 200}
            result = lambda_handler(event, None)
            mock_login.assert_called_once()

    def test_refresh_route(self):
        """Test routing to refresh handler"""
        event = {
            'httpMethod': 'POST',
            'path': '/auth/refresh',
            'body': json.dumps({
                'refreshToken': 'test-refresh-token'
            })
        }

        with patch('auth_handler.handle_refresh') as mock_refresh:
            mock_refresh.return_value = {'statusCode': 200}
            result = lambda_handler(event, None)
            mock_refresh.assert_called_once()

    def test_invalid_route(self):
        """Test handling of invalid route"""
        event = {
            'httpMethod': 'GET',
            'path': '/invalid',
            'body': '{}'
        }

        result = lambda_handler(event, None)
        assert result['statusCode'] == 404

    def test_invalid_json(self):
        """Test handling of invalid JSON"""
        event = {
            'httpMethod': 'POST',
            'path': '/auth/login',
            'body': 'invalid json'
        }

        result = lambda_handler(event, None)
        assert result['statusCode'] == 400
        body = json.loads(result['body'])
        assert 'Invalid JSON' in body['error']


class TestRegisterHandler:
    """Test user registration"""

    @patch('auth_handler.cognito_client')
    def test_successful_registration(self, mock_cognito):
        """Test successful user registration"""
        # Mock Cognito response
        mock_cognito.sign_up.return_value = {
            'UserSub': 'test-user-sub-123',
            'UserConfirmed': False
        }

        body = {
            'email': 'test@example.com',
            'password': 'SecurePass123!',
            'studyCode': 'test_study',
            'participantId': 'TEST001'
        }

        result = handle_register(body)

        # Verify response
        assert result['statusCode'] == 200
        response_body = json.loads(result['body'])
        assert response_body['userSub'] == 'test-user-sub-123'
        assert response_body['email'] == 'test@example.com'
        assert response_body['studyCode'] == 'test_study'
        assert response_body['participantId'] == 'TEST001'

        # Verify Cognito was called correctly
        mock_cognito.sign_up.assert_called_once()
        call_args = mock_cognito.sign_up.call_args
        assert call_args[1]['Username'] == 'test@example.com'
        assert call_args[1]['Password'] == 'SecurePass123!'

    @patch('auth_handler.cognito_client')
    def test_user_already_exists(self, mock_cognito):
        """Test registration with existing user"""
        # Mock Cognito error
        error_response = {'Error': {'Code': 'UsernameExistsException', 'Message': 'User exists'}}
        mock_cognito.sign_up.side_effect = ClientError(error_response, 'SignUp')

        body = {
            'email': 'test@example.com',
            'password': 'SecurePass123!',
            'studyCode': 'test_study',
            'participantId': 'TEST001'
        }

        result = handle_register(body)

        # Verify error response
        assert result['statusCode'] == 409
        response_body = json.loads(result['body'])
        assert 'already exists' in response_body['error'].lower()

    @patch('auth_handler.cognito_client')
    def test_invalid_password(self, mock_cognito):
        """Test registration with invalid password"""
        # Mock Cognito error
        error_response = {'Error': {'Code': 'InvalidPasswordException', 'Message': 'Password too weak'}}
        mock_cognito.sign_up.side_effect = ClientError(error_response, 'SignUp')

        body = {
            'email': 'test@example.com',
            'password': 'weak',
            'studyCode': 'test_study',
            'participantId': 'TEST001'
        }

        result = handle_register(body)

        # Verify error response
        assert result['statusCode'] == 400
        response_body = json.loads(result['body'])
        assert 'password' in response_body['error'].lower()

    def test_missing_required_field(self):
        """Test registration with missing field"""
        body = {
            'email': 'test@example.com',
            'password': 'SecurePass123!'
            # Missing studyCode and participantId
        }

        result = handle_register(body)

        # Should raise KeyError
        assert result['statusCode'] == 400


class TestLoginHandler:
    """Test user login"""

    @patch('auth_handler.cognito_client')
    def test_successful_login(self, mock_cognito):
        """Test successful authentication"""
        # Mock Cognito response
        mock_cognito.initiate_auth.return_value = {
            'AuthenticationResult': {
                'AccessToken': 'test-access-token',
                'IdToken': 'test-id-token',
                'RefreshToken': 'test-refresh-token',
                'ExpiresIn': 3600,
                'TokenType': 'Bearer'
            }
        }

        body = {
            'email': 'test@example.com',
            'password': 'SecurePass123!'
        }

        result = handle_login(body)

        # Verify response
        assert result['statusCode'] == 200
        response_body = json.loads(result['body'])
        assert response_body['accessToken'] == 'test-access-token'
        assert response_body['idToken'] == 'test-id-token'
        assert response_body['refreshToken'] == 'test-refresh-token'

        # Verify Cognito was called correctly
        mock_cognito.initiate_auth.assert_called_once()
        call_args = mock_cognito.initiate_auth.call_args
        assert call_args[1]['AuthFlow'] == 'USER_PASSWORD_AUTH'

    @patch('auth_handler.cognito_client')
    def test_invalid_credentials(self, mock_cognito):
        """Test login with invalid credentials"""
        # Mock Cognito error
        error_response = {'Error': {'Code': 'NotAuthorizedException', 'Message': 'Incorrect username or password'}}
        mock_cognito.initiate_auth.side_effect = ClientError(error_response, 'InitiateAuth')

        body = {
            'email': 'test@example.com',
            'password': 'WrongPassword!'
        }

        result = handle_login(body)

        # Verify error response
        assert result['statusCode'] == 401
        response_body = json.loads(result['body'])
        assert 'invalid' in response_body['error'].lower()

    @patch('auth_handler.cognito_client')
    def test_unconfirmed_user(self, mock_cognito):
        """Test login with unconfirmed user"""
        # Mock Cognito error
        error_response = {'Error': {'Code': 'UserNotConfirmedException', 'Message': 'User not confirmed'}}
        mock_cognito.initiate_auth.side_effect = ClientError(error_response, 'InitiateAuth')

        body = {
            'email': 'test@example.com',
            'password': 'SecurePass123!'
        }

        result = handle_login(body)

        # Verify error response
        assert result['statusCode'] == 403
        response_body = json.loads(result['body'])
        assert 'not verified' in response_body['error'].lower()


class TestRefreshHandler:
    """Test token refresh"""

    @patch('auth_handler.cognito_client')
    def test_successful_refresh(self, mock_cognito):
        """Test successful token refresh"""
        # Mock Cognito response
        mock_cognito.initiate_auth.return_value = {
            'AuthenticationResult': {
                'AccessToken': 'new-access-token',
                'IdToken': 'new-id-token',
                'ExpiresIn': 3600,
                'TokenType': 'Bearer'
            }
        }

        body = {
            'refreshToken': 'test-refresh-token'
        }

        result = handle_refresh(body)

        # Verify response
        assert result['statusCode'] == 200
        response_body = json.loads(result['body'])
        assert response_body['accessToken'] == 'new-access-token'
        assert response_body['idToken'] == 'new-id-token'

        # Verify Cognito was called correctly
        mock_cognito.initiate_auth.assert_called_once()
        call_args = mock_cognito.initiate_auth.call_args
        assert call_args[1]['AuthFlow'] == 'REFRESH_TOKEN_AUTH'

    @patch('auth_handler.cognito_client')
    def test_invalid_refresh_token(self, mock_cognito):
        """Test refresh with invalid token"""
        # Mock Cognito error
        error_response = {'Error': {'Code': 'NotAuthorizedException', 'Message': 'Invalid Refresh Token'}}
        mock_cognito.initiate_auth.side_effect = ClientError(error_response, 'InitiateAuth')

        body = {
            'refreshToken': 'invalid-token'
        }

        result = handle_refresh(body)

        # Verify error response
        assert result['statusCode'] == 401
        response_body = json.loads(result['body'])
        assert 'invalid' in response_body['error'].lower()


class TestResponseHelpers:
    """Test response helper functions"""

    def test_success_response(self):
        """Test success response format"""
        data = {'message': 'Success'}
        result = success_response(data)

        assert result['statusCode'] == 200
        assert result['headers']['Content-Type'] == 'application/json'
        assert result['headers']['Access-Control-Allow-Origin'] == '*'
        body = json.loads(result['body'])
        assert body['message'] == 'Success'

    def test_error_response(self):
        """Test error response format"""
        result = error_response(400, 'Bad Request')

        assert result['statusCode'] == 400
        assert result['headers']['Content-Type'] == 'application/json'
        body = json.loads(result['body'])
        assert body['error'] == 'Bad Request'

    def test_custom_status_code(self):
        """Test custom status code"""
        result = success_response({'data': 'test'}, status_code=201)
        assert result['statusCode'] == 201
