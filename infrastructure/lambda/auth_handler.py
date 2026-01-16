"""
OSRP Authentication Lambda Handler

Handles user authentication via AWS Cognito:
- POST /auth/register - User registration
- POST /auth/login - User sign in
- POST /auth/refresh - Token refresh
"""

import json
import logging
import os
from typing import Dict, Any

import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Cognito client
cognito_client = boto3.client('cognito-idp')

# Environment variables
USER_POOL_ID = os.environ['USER_POOL_ID']
CLIENT_ID = os.environ['CLIENT_ID']


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for authentication endpoints.

    Args:
        event: API Gateway event
        context: Lambda context

    Returns:
        API Gateway response
    """
    try:
        # Parse request
        http_method = event['httpMethod']
        path = event['path']
        body = json.loads(event.get('body', '{}'))

        logger.info(f"Request: {http_method} {path}")

        # Route to appropriate handler
        if path == '/auth/register' and http_method == 'POST':
            return handle_register(body)
        elif path == '/auth/login' and http_method == 'POST':
            return handle_login(body)
        elif path == '/auth/refresh' and http_method == 'POST':
            return handle_refresh(body)
        else:
            return error_response(404, 'Not Found')

    except json.JSONDecodeError:
        return error_response(400, 'Invalid JSON')
    except KeyError as e:
        return error_response(400, f'Missing required field: {str(e)}')
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return error_response(500, 'Internal server error')


def handle_register(body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle user registration.

    Request body:
    {
        "email": "participant@example.com",
        "password": "SecurePass123!",
        "studyCode": "depression_study_2026",
        "participantId": "P001"
    }

    Returns:
        API Gateway response with user info
    """
    try:
        # Validate required fields
        email = body['email']
        password = body['password']
        study_code = body['studyCode']
        participant_id = body['participantId']

        logger.info(f"Registering user: {email}")

        # Sign up user in Cognito
        response = cognito_client.sign_up(
            ClientId=CLIENT_ID,
            Username=email,
            Password=password,
            UserAttributes=[
                {'Name': 'email', 'Value': email},
                {'Name': 'custom:studyCode', 'Value': study_code},
                {'Name': 'custom:participantId', 'Value': participant_id}
            ]
        )

        logger.info(f"User registered successfully: {email}")

        return success_response({
            'message': 'User registered successfully',
            'userSub': response['UserSub'],
            'userConfirmed': response['UserConfirmed'],
            'email': email,
            'studyCode': study_code,
            'participantId': participant_id
        })

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']

        logger.warning(f"Registration failed: {error_code} - {error_message}")

        if error_code == 'UsernameExistsException':
            return error_response(409, 'User already exists')
        elif error_code == 'InvalidPasswordException':
            return error_response(400, 'Password does not meet requirements')
        elif error_code == 'InvalidParameterException':
            return error_response(400, error_message)
        else:
            return error_response(500, f'Registration failed: {error_message}')


def handle_login(body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle user login.

    Request body:
    {
        "email": "participant@example.com",
        "password": "SecurePass123!"
    }

    Returns:
        API Gateway response with tokens
    """
    try:
        # Validate required fields
        email = body['email']
        password = body['password']

        logger.info(f"Authenticating user: {email}")

        # Authenticate user
        response = cognito_client.initiate_auth(
            ClientId=CLIENT_ID,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': email,
                'PASSWORD': password
            }
        )

        # Check if challenge is required (e.g., NEW_PASSWORD_REQUIRED)
        if 'ChallengeName' in response:
            logger.info(f"Auth challenge required: {response['ChallengeName']}")
            return success_response({
                'challenge': response['ChallengeName'],
                'session': response['Session']
            })

        # Extract tokens
        auth_result = response['AuthenticationResult']

        logger.info(f"User authenticated successfully: {email}")

        return success_response({
            'accessToken': auth_result['AccessToken'],
            'idToken': auth_result['IdToken'],
            'refreshToken': auth_result['RefreshToken'],
            'expiresIn': auth_result['ExpiresIn'],
            'tokenType': auth_result['TokenType']
        })

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']

        logger.warning(f"Authentication failed: {error_code} - {error_message}")

        if error_code == 'NotAuthorizedException':
            return error_response(401, 'Invalid email or password')
        elif error_code == 'UserNotConfirmedException':
            return error_response(403, 'User email not verified')
        elif error_code == 'UserNotFoundException':
            return error_response(401, 'Invalid email or password')
        else:
            return error_response(500, f'Authentication failed: {error_message}')


def handle_refresh(body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle token refresh.

    Request body:
    {
        "refreshToken": "eyJjdHk..."
    }

    Returns:
        API Gateway response with new tokens
    """
    try:
        # Validate required fields
        refresh_token = body['refreshToken']

        logger.info("Refreshing access token")

        # Refresh tokens
        response = cognito_client.initiate_auth(
            ClientId=CLIENT_ID,
            AuthFlow='REFRESH_TOKEN_AUTH',
            AuthParameters={
                'REFRESH_TOKEN': refresh_token
            }
        )

        # Extract new tokens
        auth_result = response['AuthenticationResult']

        logger.info("Token refreshed successfully")

        return success_response({
            'accessToken': auth_result['AccessToken'],
            'idToken': auth_result['IdToken'],
            'expiresIn': auth_result['ExpiresIn'],
            'tokenType': auth_result['TokenType']
        })

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']

        logger.warning(f"Token refresh failed: {error_code} - {error_message}")

        if error_code == 'NotAuthorizedException':
            return error_response(401, 'Invalid or expired refresh token')
        else:
            return error_response(500, f'Token refresh failed: {error_message}')


def success_response(data: Dict[str, Any], status_code: int = 200) -> Dict[str, Any]:
    """
    Create a successful API Gateway response.

    Args:
        data: Response data
        status_code: HTTP status code

    Returns:
        API Gateway response
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',  # CORS
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        },
        'body': json.dumps(data)
    }


def error_response(status_code: int, message: str) -> Dict[str, Any]:
    """
    Create an error API Gateway response.

    Args:
        status_code: HTTP status code
        message: Error message

    Returns:
        API Gateway response
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',  # CORS
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        },
        'body': json.dumps({
            'error': message
        })
    }
