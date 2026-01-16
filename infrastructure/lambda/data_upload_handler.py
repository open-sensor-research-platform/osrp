"""
OSRP Data Upload Lambda Handler

Handles data uploads from mobile apps:
- POST /data/sensor - Upload sensor time series data
- POST /data/event - Upload discrete events
- GET /data/presigned-url - Generate presigned S3 URLs
- POST /data/device-state - Upload device state
"""

import json
import logging
import os
import time
from datetime import datetime, timedelta
from typing import Dict, Any, List
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients
dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')

# Environment variables
SENSOR_TABLE_NAME = os.environ['SENSOR_TABLE_NAME']
EVENT_TABLE_NAME = os.environ['EVENT_TABLE_NAME']
DEVICE_STATE_TABLE_NAME = os.environ['DEVICE_STATE_TABLE_NAME']
PARTICIPANT_TABLE_NAME = os.environ['PARTICIPANT_TABLE_NAME']
DATA_BUCKET_NAME = os.environ['DATA_BUCKET_NAME']

# DynamoDB tables
sensor_table = dynamodb.Table(SENSOR_TABLE_NAME)
event_table = dynamodb.Table(EVENT_TABLE_NAME)
device_state_table = dynamodb.Table(DEVICE_STATE_TABLE_NAME)
participant_table = dynamodb.Table(PARTICIPANT_TABLE_NAME)


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for data upload endpoints.

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
        body = json.loads(event.get('body', '{}')) if event.get('body') else {}
        query_params = event.get('queryStringParameters', {}) or {}

        logger.info(f"Request: {http_method} {path}")

        # Extract user ID from JWT token
        user_id = extract_user_id(event)
        if not user_id:
            return error_response(401, 'Unauthorized - Invalid token')

        # Route to appropriate handler
        if path == '/data/sensor' and http_method == 'POST':
            return handle_sensor_upload(user_id, body)
        elif path == '/data/event' and http_method == 'POST':
            return handle_event_upload(user_id, body)
        elif path == '/data/device-state' and http_method == 'POST':
            return handle_device_state_upload(user_id, body)
        elif path == '/data/presigned-url' and http_method == 'GET':
            return handle_presigned_url(user_id, query_params)
        else:
            return error_response(404, 'Not Found')

    except json.JSONDecodeError:
        return error_response(400, 'Invalid JSON')
    except KeyError as e:
        return error_response(400, f'Missing required field: {str(e)}')
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return error_response(500, 'Internal server error')


def extract_user_id(event: Dict[str, Any]) -> str:
    """
    Extract user ID from JWT token in Authorization header.

    Args:
        event: API Gateway event

    Returns:
        User ID (sub) from token, or None if not found
    """
    try:
        # Get user ID from authorizer context (set by API Gateway)
        if 'requestContext' in event and 'authorizer' in event['requestContext']:
            claims = event['requestContext']['authorizer'].get('claims', {})
            return claims.get('sub') or claims.get('cognito:username')
        return None
    except Exception as e:
        logger.warning(f"Failed to extract user ID: {str(e)}")
        return None


def handle_sensor_upload(user_id: str, body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle sensor time series data upload.

    Request body:
    {
        "sensorType": "accelerometer",
        "readings": [
            {
                "timestamp": 1705334400123,
                "data": {"x": 0.234, "y": -9.812, "z": 0.156},
                "accuracy": 3
            }
        ],
        "studyCode": "depression_study_2026"
    }

    Returns:
        API Gateway response
    """
    try:
        # Validate required fields
        sensor_type = body['sensorType']
        readings = body['readings']
        study_code = body['studyCode']

        logger.info(f"Uploading {len(readings)} {sensor_type} readings for user {user_id}")

        # Validate readings
        if not isinstance(readings, list) or len(readings) == 0:
            return error_response(400, 'readings must be a non-empty array')

        if len(readings) > 1000:
            return error_response(400, 'Maximum 1000 readings per request')

        # Prepare items for batch write
        items = []
        current_time = int(time.time())
        ttl_days = 90
        expiration_time = current_time + (ttl_days * 24 * 60 * 60)

        for reading in readings:
            # Validate reading structure
            if 'timestamp' not in reading or 'data' not in reading:
                return error_response(400, 'Each reading must have timestamp and data')

            # Convert floats to Decimal for DynamoDB
            data = convert_floats_to_decimal(reading['data'])

            item = {
                'userIdSensorType': f"{user_id}#{sensor_type}",
                'timestamp': int(reading['timestamp']),
                'groupCode': study_code,
                'data': data,
                'accuracy': reading.get('accuracy'),
                'expirationTime': expiration_time
            }
            items.append(item)

        # Batch write to DynamoDB
        write_count = 0
        with sensor_table.batch_writer() as batch:
            for item in items:
                batch.put_item(Item=item)
                write_count += 1

        # Update participant last seen timestamp
        update_participant_last_seen(user_id, study_code)

        logger.info(f"Successfully uploaded {write_count} {sensor_type} readings")

        return success_response({
            'message': 'Sensor data uploaded successfully',
            'count': write_count,
            'sensorType': sensor_type
        })

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        logger.error(f"DynamoDB error: {error_code} - {error_message}")
        return error_response(500, f'Database error: {error_message}')


def handle_event_upload(user_id: str, body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle discrete event upload.

    Request body:
    {
        "eventType": "app_launch",
        "timestamp": 1705334400123,
        "eventData": {"appVersion": "0.3.0", "sessionId": "abc123"},
        "context": {"batteryLevel": 85, "networkType": "wifi"},
        "studyCode": "depression_study_2026"
    }

    Returns:
        API Gateway response
    """
    try:
        # Validate required fields
        event_type = body['eventType']
        timestamp = int(body['timestamp'])
        study_code = body['studyCode']
        event_data = body.get('eventData', {})
        context = body.get('context', {})

        logger.info(f"Logging {event_type} event for user {user_id}")

        # Convert floats to Decimal
        event_data = convert_floats_to_decimal(event_data)
        context = convert_floats_to_decimal(context)

        # Set TTL (90 days)
        current_time = int(time.time())
        expiration_time = current_time + (90 * 24 * 60 * 60)

        # Write to DynamoDB
        item = {
            'userId': user_id,
            'timestampEventType': f"{timestamp}#{event_type}",
            'groupCode': study_code,
            'eventType': event_type,
            'eventData': event_data,
            'context': context,
            'expirationTime': expiration_time
        }

        event_table.put_item(Item=item)

        # Update participant last seen
        update_participant_last_seen(user_id, study_code)

        logger.info(f"Successfully logged {event_type} event")

        return success_response({
            'message': 'Event logged successfully',
            'eventType': event_type,
            'timestamp': timestamp
        })

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        logger.error(f"DynamoDB error: {error_code} - {error_message}")
        return error_response(500, f'Database error: {error_message}')


def handle_device_state_upload(user_id: str, body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle device state snapshot upload.

    Request body:
    {
        "timestamp": 1705334400000,
        "studyCode": "depression_study_2026",
        "batteryLevel": 85,
        "batteryCharging": false,
        "networkType": "wifi",
        "storageAvailable": 5368709120,
        "storageTotal": 10737418240,
        "appVersion": "0.3.0",
        "osVersion": "Fire OS 8"
    }

    Returns:
        API Gateway response
    """
    try:
        # Validate required fields
        timestamp = int(body['timestamp'])
        study_code = body['studyCode']

        logger.info(f"Uploading device state for user {user_id}")

        # Convert floats to Decimal
        body_decimal = convert_floats_to_decimal(body)

        # Set TTL (90 days)
        current_time = int(time.time())
        expiration_time = current_time + (90 * 24 * 60 * 60)

        # Write to DynamoDB
        item = {
            'userId': user_id,
            'timestamp': timestamp,
            'groupCode': study_code,
            'batteryLevel': body_decimal.get('batteryLevel'),
            'batteryCharging': body.get('batteryCharging'),
            'networkType': body.get('networkType'),
            'storageAvailable': body_decimal.get('storageAvailable'),
            'storageTotal': body_decimal.get('storageTotal'),
            'memoryAvailable': body_decimal.get('memoryAvailable'),
            'memoryTotal': body_decimal.get('memoryTotal'),
            'appVersion': body.get('appVersion'),
            'osVersion': body.get('osVersion'),
            'expirationTime': expiration_time
        }

        device_state_table.put_item(Item=item)

        # Update participant last seen
        update_participant_last_seen(user_id, study_code)

        logger.info("Successfully uploaded device state")

        return success_response({
            'message': 'Device state uploaded successfully',
            'timestamp': timestamp
        })

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        logger.error(f"DynamoDB error: {error_code} - {error_message}")
        return error_response(500, f'Database error: {error_message}')


def handle_presigned_url(user_id: str, query_params: Dict[str, str]) -> Dict[str, Any]:
    """
    Generate presigned S3 URL for file upload.

    Query parameters:
    - key: S3 object key (e.g., "raw/screenshots/userId/2026-01-16/timestamp.png")
    - contentType: Content type (e.g., "image/png")
    - expiresIn: URL expiration in seconds (default: 3600)

    Returns:
        API Gateway response with presigned URL
    """
    try:
        # Validate required parameters
        if 'key' not in query_params:
            return error_response(400, 'Missing required parameter: key')

        key = query_params['key']
        content_type = query_params.get('contentType', 'application/octet-stream')
        expires_in = int(query_params.get('expiresIn', '3600'))

        # Validate key starts with allowed prefixes
        allowed_prefixes = ['raw/', 'temp/']
        if not any(key.startswith(prefix) for prefix in allowed_prefixes):
            return error_response(400, 'Key must start with raw/ or temp/')

        # Validate key contains user ID for security
        if user_id not in key:
            return error_response(403, 'Key must contain user ID')

        logger.info(f"Generating presigned URL for key: {key}")

        # Generate presigned URL
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': DATA_BUCKET_NAME,
                'Key': key,
                'ContentType': content_type
            },
            ExpiresIn=expires_in
        )

        logger.info("Successfully generated presigned URL")

        return success_response({
            'uploadUrl': presigned_url,
            'key': key,
            'expiresIn': expires_in
        })

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        logger.error(f"S3 error: {error_code} - {error_message}")
        return error_response(500, f'S3 error: {error_message}')


def update_participant_last_seen(user_id: str, study_code: str) -> None:
    """
    Update participant's last seen timestamp.

    Args:
        user_id: Participant user ID
        study_code: Study code
    """
    try:
        current_timestamp = int(time.time() * 1000)
        participant_table.update_item(
            Key={'userId': user_id},
            UpdateExpression='SET lastSeenTimestamp = :ts, lastUploadTimestamp = :ts, groupCode = :gc',
            ExpressionAttributeValues={
                ':ts': current_timestamp,
                ':gc': study_code
            }
        )
    except Exception as e:
        # Don't fail the request if this update fails
        logger.warning(f"Failed to update participant last seen: {str(e)}")


def convert_floats_to_decimal(obj: Any) -> Any:
    """
    Convert floats to Decimal for DynamoDB compatibility.

    Args:
        obj: Object to convert (dict, list, or primitive)

    Returns:
        Converted object with Decimal instead of float
    """
    if isinstance(obj, dict):
        return {k: convert_floats_to_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_floats_to_decimal(item) for item in obj]
    elif isinstance(obj, float):
        return Decimal(str(obj))
    else:
        return obj


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
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
        },
        'body': json.dumps(data, default=str)
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
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
        },
        'body': json.dumps({
            'error': message
        })
    }
