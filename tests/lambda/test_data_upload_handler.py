"""
Unit tests for data upload Lambda handler
"""

import json
import pytest
from unittest.mock import Mock, patch, MagicMock
from decimal import Decimal
from botocore.exceptions import ClientError


# Mock environment variables before importing handler
@pytest.fixture(autouse=True)
def mock_env_vars(monkeypatch):
    """Mock environment variables for Lambda"""
    monkeypatch.setenv('SENSOR_TABLE_NAME', 'osrp-SensorTimeSeries-dev')
    monkeypatch.setenv('EVENT_TABLE_NAME', 'osrp-EventLog-dev')
    monkeypatch.setenv('DEVICE_STATE_TABLE_NAME', 'osrp-DeviceState-dev')
    monkeypatch.setenv('PARTICIPANT_TABLE_NAME', 'osrp-ParticipantStatus-dev')
    monkeypatch.setenv('DATA_BUCKET_NAME', 'osrp-data-dev-123456789012')


# Import after mocking env vars
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../infrastructure/lambda'))
from data_upload_handler import (
    lambda_handler,
    handle_sensor_upload,
    handle_event_upload,
    handle_device_state_upload,
    handle_presigned_url,
    extract_user_id,
    convert_floats_to_decimal,
    success_response,
    error_response
)


class TestLambdaHandler:
    """Test main Lambda handler routing"""

    def test_sensor_route(self):
        """Test routing to sensor handler"""
        event = {
            'httpMethod': 'POST',
            'path': '/data/sensor',
            'body': json.dumps({
                'sensorType': 'accelerometer',
                'readings': [{'timestamp': 123, 'data': {'x': 1.0}}],
                'studyCode': 'test'
            }),
            'requestContext': {
                'authorizer': {
                    'claims': {'sub': 'user-123'}
                }
            }
        }

        with patch('data_upload_handler.handle_sensor_upload') as mock:
            mock.return_value = {'statusCode': 200}
            result = lambda_handler(event, None)
            mock.assert_called_once()

    def test_event_route(self):
        """Test routing to event handler"""
        event = {
            'httpMethod': 'POST',
            'path': '/data/event',
            'body': json.dumps({
                'eventType': 'app_launch',
                'timestamp': 123,
                'studyCode': 'test'
            }),
            'requestContext': {
                'authorizer': {
                    'claims': {'sub': 'user-123'}
                }
            }
        }

        with patch('data_upload_handler.handle_event_upload') as mock:
            mock.return_value = {'statusCode': 200}
            result = lambda_handler(event, None)
            mock.assert_called_once()

    def test_presigned_url_route(self):
        """Test routing to presigned URL handler"""
        event = {
            'httpMethod': 'GET',
            'path': '/data/presigned-url',
            'queryStringParameters': {'key': 'raw/test/user-123/file.png'},
            'requestContext': {
                'authorizer': {
                    'claims': {'sub': 'user-123'}
                }
            }
        }

        with patch('data_upload_handler.handle_presigned_url') as mock:
            mock.return_value = {'statusCode': 200}
            result = lambda_handler(event, None)
            mock.assert_called_once()

    def test_unauthorized_request(self):
        """Test request without user ID"""
        event = {
            'httpMethod': 'POST',
            'path': '/data/sensor',
            'body': '{}'
        }

        result = lambda_handler(event, None)
        assert result['statusCode'] == 401


class TestExtractUserId:
    """Test user ID extraction from JWT token"""

    def test_extract_from_sub(self):
        """Test extracting user ID from sub claim"""
        event = {
            'requestContext': {
                'authorizer': {
                    'claims': {'sub': 'user-123'}
                }
            }
        }

        user_id = extract_user_id(event)
        assert user_id == 'user-123'

    def test_extract_from_cognito_username(self):
        """Test extracting user ID from cognito:username"""
        event = {
            'requestContext': {
                'authorizer': {
                    'claims': {'cognito:username': 'user-456'}
                }
            }
        }

        user_id = extract_user_id(event)
        assert user_id == 'user-456'

    def test_missing_authorizer(self):
        """Test extraction when authorizer is missing"""
        event = {'requestContext': {}}

        user_id = extract_user_id(event)
        assert user_id is None


class TestSensorUpload:
    """Test sensor data upload"""

    @patch('data_upload_handler.sensor_table')
    @patch('data_upload_handler.update_participant_last_seen')
    def test_successful_upload(self, mock_update, mock_table):
        """Test successful sensor data upload"""
        # Mock batch writer
        mock_batch = MagicMock()
        mock_table.batch_writer.return_value.__enter__.return_value = mock_batch

        body = {
            'sensorType': 'accelerometer',
            'readings': [
                {
                    'timestamp': 1705334400123,
                    'data': {'x': 0.234, 'y': -9.812, 'z': 0.156},
                    'accuracy': 3
                }
            ],
            'studyCode': 'test_study'
        }

        result = handle_sensor_upload('user-123', body)

        # Verify response
        assert result['statusCode'] == 200
        response_body = json.loads(result['body'])
        assert response_body['count'] == 1
        assert response_body['sensorType'] == 'accelerometer'

        # Verify batch writer was called
        mock_batch.put_item.assert_called_once()

        # Verify participant last seen was updated
        mock_update.assert_called_once_with('user-123', 'test_study')

    @patch('data_upload_handler.sensor_table')
    def test_batch_upload(self, mock_table):
        """Test uploading multiple readings"""
        mock_batch = MagicMock()
        mock_table.batch_writer.return_value.__enter__.return_value = mock_batch

        readings = [
            {'timestamp': i, 'data': {'x': float(i)}}
            for i in range(100)
        ]

        body = {
            'sensorType': 'accelerometer',
            'readings': readings,
            'studyCode': 'test_study'
        }

        with patch('data_upload_handler.update_participant_last_seen'):
            result = handle_sensor_upload('user-123', body)

        # Verify all readings were written
        assert mock_batch.put_item.call_count == 100

    def test_empty_readings(self):
        """Test upload with empty readings array"""
        body = {
            'sensorType': 'accelerometer',
            'readings': [],
            'studyCode': 'test_study'
        }

        result = handle_sensor_upload('user-123', body)
        assert result['statusCode'] == 400

    def test_too_many_readings(self):
        """Test upload exceeding maximum readings"""
        body = {
            'sensorType': 'accelerometer',
            'readings': [{'timestamp': i, 'data': {'x': 1.0}} for i in range(1001)],
            'studyCode': 'test_study'
        }

        result = handle_sensor_upload('user-123', body)
        assert result['statusCode'] == 400

    def test_invalid_reading_structure(self):
        """Test upload with invalid reading"""
        body = {
            'sensorType': 'accelerometer',
            'readings': [{'data': {'x': 1.0}}],  # Missing timestamp
            'studyCode': 'test_study'
        }

        result = handle_sensor_upload('user-123', body)
        assert result['statusCode'] == 400


class TestEventUpload:
    """Test event logging"""

    @patch('data_upload_handler.event_table')
    @patch('data_upload_handler.update_participant_last_seen')
    def test_successful_event_upload(self, mock_update, mock_table):
        """Test successful event logging"""
        body = {
            'eventType': 'app_launch',
            'timestamp': 1705334400123,
            'studyCode': 'test_study',
            'eventData': {'appVersion': '0.3.0'},
            'context': {'batteryLevel': 85}
        }

        result = handle_event_upload('user-123', body)

        # Verify response
        assert result['statusCode'] == 200
        response_body = json.loads(result['body'])
        assert response_body['eventType'] == 'app_launch'

        # Verify DynamoDB put_item was called
        mock_table.put_item.assert_called_once()

        # Verify participant last seen was updated
        mock_update.assert_called_once_with('user-123', 'test_study')

    @patch('data_upload_handler.event_table')
    def test_event_with_minimal_data(self, mock_table):
        """Test event logging with minimal data"""
        body = {
            'eventType': 'app_launch',
            'timestamp': 1705334400123,
            'studyCode': 'test_study'
        }

        with patch('data_upload_handler.update_participant_last_seen'):
            result = handle_event_upload('user-123', body)

        assert result['statusCode'] == 200
        mock_table.put_item.assert_called_once()


class TestDeviceStateUpload:
    """Test device state upload"""

    @patch('data_upload_handler.device_state_table')
    @patch('data_upload_handler.update_participant_last_seen')
    def test_successful_device_state_upload(self, mock_update, mock_table):
        """Test successful device state upload"""
        body = {
            'timestamp': 1705334400000,
            'studyCode': 'test_study',
            'batteryLevel': 85,
            'batteryCharging': False,
            'networkType': 'wifi',
            'storageAvailable': 5368709120,
            'appVersion': '0.3.0'
        }

        result = handle_device_state_upload('user-123', body)

        # Verify response
        assert result['statusCode'] == 200
        response_body = json.loads(result['body'])
        assert response_body['timestamp'] == 1705334400000

        # Verify DynamoDB put_item was called
        mock_table.put_item.assert_called_once()

        # Verify participant last seen was updated
        mock_update.assert_called_once_with('user-123', 'test_study')


class TestPresignedUrl:
    """Test presigned URL generation"""

    @patch('data_upload_handler.s3_client')
    def test_successful_presigned_url(self, mock_s3):
        """Test successful presigned URL generation"""
        mock_s3.generate_presigned_url.return_value = 'https://s3.example.com/upload'

        query_params = {
            'key': 'raw/screenshots/user-123/file.png',
            'contentType': 'image/png'
        }

        result = handle_presigned_url('user-123', query_params)

        # Verify response
        assert result['statusCode'] == 200
        response_body = json.loads(result['body'])
        assert 'uploadUrl' in response_body
        assert response_body['key'] == 'raw/screenshots/user-123/file.png'

        # Verify S3 client was called
        mock_s3.generate_presigned_url.assert_called_once()

    def test_missing_key(self):
        """Test presigned URL without key parameter"""
        result = handle_presigned_url('user-123', {})
        assert result['statusCode'] == 400

    def test_invalid_prefix(self):
        """Test presigned URL with invalid prefix"""
        query_params = {
            'key': 'invalid/user-123/file.png'
        }

        result = handle_presigned_url('user-123', query_params)
        assert result['statusCode'] == 400

    def test_missing_user_id_in_key(self):
        """Test presigned URL without user ID in key"""
        query_params = {
            'key': 'raw/screenshots/other-user/file.png'
        }

        result = handle_presigned_url('user-123', query_params)
        assert result['statusCode'] == 403

    @patch('data_upload_handler.s3_client')
    def test_custom_expiration(self, mock_s3):
        """Test presigned URL with custom expiration"""
        mock_s3.generate_presigned_url.return_value = 'https://s3.example.com/upload'

        query_params = {
            'key': 'raw/user-123/file.png',
            'expiresIn': '7200'
        }

        result = handle_presigned_url('user-123', query_params)

        # Verify custom expiration was used
        call_args = mock_s3.generate_presigned_url.call_args
        assert call_args[1]['ExpiresIn'] == 7200


class TestHelperFunctions:
    """Test helper functions"""

    def test_convert_floats_to_decimal(self):
        """Test float to Decimal conversion"""
        obj = {
            'float_val': 1.5,
            'int_val': 10,
            'str_val': 'test',
            'nested': {'x': 0.234, 'y': -9.812},
            'list': [1.0, 2.0, 3.0]
        }

        result = convert_floats_to_decimal(obj)

        assert isinstance(result['float_val'], Decimal)
        assert isinstance(result['int_val'], int)
        assert isinstance(result['str_val'], str)
        assert isinstance(result['nested']['x'], Decimal)
        assert isinstance(result['list'][0], Decimal)

    def test_success_response(self):
        """Test success response format"""
        data = {'message': 'Success', 'count': 10}
        result = success_response(data)

        assert result['statusCode'] == 200
        assert result['headers']['Content-Type'] == 'application/json'
        assert result['headers']['Access-Control-Allow-Origin'] == '*'
        body = json.loads(result['body'])
        assert body['message'] == 'Success'
        assert body['count'] == 10

    def test_error_response(self):
        """Test error response format"""
        result = error_response(400, 'Bad Request')

        assert result['statusCode'] == 400
        assert result['headers']['Content-Type'] == 'application/json'
        body = json.loads(result['body'])
        assert body['error'] == 'Bad Request'


class TestUpdateParticipantLastSeen:
    """Test participant last seen update"""

    @patch('data_upload_handler.participant_table')
    def test_successful_update(self, mock_table):
        """Test successful last seen update"""
        from data_upload_handler import update_participant_last_seen

        update_participant_last_seen('user-123', 'test_study')

        # Verify update_item was called
        mock_table.update_item.assert_called_once()
        call_args = mock_table.update_item.call_args
        assert call_args[1]['Key'] == {'userId': 'user-123'}

    @patch('data_upload_handler.participant_table')
    def test_failed_update_does_not_raise(self, mock_table):
        """Test failed update doesn't raise exception"""
        from data_upload_handler import update_participant_last_seen

        mock_table.update_item.side_effect = Exception('DynamoDB error')

        # Should not raise exception
        update_participant_last_seen('user-123', 'test_study')
