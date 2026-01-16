# OSRP DynamoDB Schema Documentation

## Overview

This document describes the DynamoDB table schema for OSRP MVP.

**Version**: 0.2.0 (MVP)
**CloudFormation Template**: `cloudformation-dynamodb.yaml`

---

## Tables

### 1. ParticipantStatus

**Purpose**: Track participant enrollment, device info, and data collection status

**Key Schema**:
- **Partition Key**: `userId` (String)

**Attributes**:
```json
{
  "userId": "participant_001",
  "groupCode": "study_001",
  "email": "participant@example.com",
  "enrolledAt": 1705334400000,
  "lastSeenTimestamp": 1705420800000,
  "deviceInfo": {
    "deviceModel": "Amazon Fire HD 10",
    "osVersion": "Fire OS 8",
    "appVersion": "0.3.0",
    "platform": "android"
  },
  "dataCollectionStatus": "active",
  "sensorCount": 1,
  "lastUploadTimestamp": 1705420700000
}
```

**Global Secondary Indexes**:
- `groupCode-lastSeen-index`: Query participants by study group, sorted by last activity

**Common Queries**:
```python
# Get participant info
response = table.get_item(Key={'userId': 'participant_001'})

# List participants in a study, sorted by last seen
response = table.query(
    IndexName='groupCode-lastSeen-index',
    KeyConditionExpression='groupCode = :group',
    ExpressionAttributeValues={':group': 'study_001'},
    ScanIndexForward=False  # Most recent first
)

# Update last seen timestamp
table.update_item(
    Key={'userId': 'participant_001'},
    UpdateExpression='SET lastSeenTimestamp = :ts',
    ExpressionAttributeValues={':ts': int(time.time() * 1000)}
)
```

---

### 2. SensorTimeSeries

**Purpose**: Store time series sensor data (accelerometer, steps, heart rate, etc.)

**Key Schema**:
- **Partition Key**: `userIdSensorType` (String) - Format: `userId#sensorType`
- **Sort Key**: `timestamp` (Number) - Unix timestamp in milliseconds

**Attributes**:
```json
{
  "userIdSensorType": "participant_001#accelerometer",
  "timestamp": 1705334400123,
  "groupCode": "study_001",
  "data": {
    "x": 0.234,
    "y": -9.812,
    "z": 0.156
  },
  "accuracy": 3,
  "expirationTime": 1712937600  // TTL: expires after 90 days
}
```

**Example iOS HealthKit Data**:
```json
{
  "userIdSensorType": "participant_002#steps",
  "timestamp": 1705334400000,
  "groupCode": "study_001",
  "data": {
    "stepCount": 8453,
    "startTime": 1705334400000,
    "endTime": 1705420800000
  },
  "source": "HealthKit",
  "expirationTime": 1712937600
}
```

**Global Secondary Indexes**:
- `groupCode-timestamp-index`: Query all sensor data for a study by time range

**Common Queries**:
```python
# Get accelerometer data for a user in time range
response = table.query(
    KeyConditionExpression='userIdSensorType = :key AND #ts BETWEEN :start AND :end',
    ExpressionAttributeNames={'#ts': 'timestamp'},
    ExpressionAttributeValues={
        ':key': 'participant_001#accelerometer',
        ':start': 1705334400000,
        ':end': 1705420800000
    }
)

# Get all sensor data for a study in time range
response = table.query(
    IndexName='groupCode-timestamp-index',
    KeyConditionExpression='groupCode = :group AND #ts BETWEEN :start AND :end',
    ExpressionAttributeNames={'#ts': 'timestamp'},
    ExpressionAttributeValues={
        ':group': 'study_001',
        ':start': 1705334400000,
        ':end': 1705420800000
    }
)

# Batch write sensor readings
with table.batch_writer() as batch:
    for reading in sensor_readings:
        batch.put_item(Item={
            'userIdSensorType': f'{user_id}#accelerometer',
            'timestamp': reading['timestamp'],
            'groupCode': group_code,
            'data': reading['data'],
            'accuracy': reading['accuracy'],
            'expirationTime': int(time.time()) + 7776000  # 90 days
        })
```

**Sensor Types** (MVP):
- `accelerometer` - Android accelerometer (x, y, z)
- `steps` - iOS HealthKit daily steps

**Future Sensor Types**:
- `gyroscope`, `magnetometer`, `location`, `heart_rate`, `sleep`, etc.

---

### 3. EventLog

**Purpose**: Store discrete events (app launches, state changes, user actions)

**Key Schema**:
- **Partition Key**: `userId` (String)
- **Sort Key**: `timestampEventType` (String) - Format: `timestamp#eventType`

**Attributes**:
```json
{
  "userId": "participant_001",
  "timestampEventType": "1705334400123#app_launch",
  "groupCode": "study_001",
  "eventType": "app_launch",
  "eventData": {
    "appVersion": "0.3.0",
    "sessionId": "abc123"
  },
  "context": {
    "batteryLevel": 85,
    "networkType": "wifi",
    "location": {
      "lat": 37.7749,
      "lon": -122.4194
    }
  },
  "expirationTime": 1712937600
}
```

**Event Types** (MVP):
- `app_launch` - App started
- `app_background` - App moved to background
- `data_upload_start` - Upload initiated
- `data_upload_success` - Upload completed
- `data_upload_failed` - Upload failed
- `auth_login` - User logged in
- `auth_logout` - User logged out
- `sensor_start` - Sensor collection started
- `sensor_stop` - Sensor collection stopped

**Global Secondary Indexes**:
- `groupCode-eventType-index`: Query events by study and event type

**Common Queries**:
```python
# Get events for a user in time range
response = table.query(
    KeyConditionExpression='userId = :user AND timestampEventType BETWEEN :start AND :end',
    ExpressionAttributeValues={
        ':user': 'participant_001',
        ':start': '1705334400000#',
        ':end': '1705420800000#~'  # ~ sorts after all event types
    }
)

# Get specific event type for all participants in a study
response = table.query(
    IndexName='groupCode-eventType-index',
    KeyConditionExpression='groupCode = :group AND eventType = :type',
    ExpressionAttributeValues={
        ':group': 'study_001',
        ':type': 'data_upload_failed'
    }
)

# Log event
table.put_item(Item={
    'userId': user_id,
    'timestampEventType': f'{timestamp}#{event_type}',
    'groupCode': group_code,
    'eventType': event_type,
    'eventData': event_data,
    'context': context,
    'expirationTime': int(time.time()) + 7776000
})
```

---

### 4. DeviceState

**Purpose**: Store periodic device state snapshots (battery, connectivity, storage)

**Key Schema**:
- **Partition Key**: `userId` (String)
- **Sort Key**: `timestamp` (Number) - Unix timestamp in milliseconds

**Attributes**:
```json
{
  "userId": "participant_001",
  "timestamp": 1705334400000,
  "groupCode": "study_001",
  "batteryLevel": 85,
  "batteryCharging": false,
  "networkType": "wifi",
  "storageAvailable": 5368709120,
  "storageTotal": 10737418240,
  "memoryAvailable": 2147483648,
  "memoryTotal": 4294967296,
  "appVersion": "0.3.0",
  "osVersion": "Fire OS 8",
  "expirationTime": 1712937600
}
```

**Global Secondary Indexes**:
- `groupCode-timestamp-index`: Query device states by study and time

**Common Queries**:
```python
# Get device state snapshots for a user
response = table.query(
    KeyConditionExpression='userId = :user AND #ts BETWEEN :start AND :end',
    ExpressionAttributeNames={'#ts': 'timestamp'},
    ExpressionAttributeValues={
        ':user': 'participant_001',
        ':start': 1705334400000,
        ':end': 1705420800000
    }
)

# Get latest device state for a user
response = table.query(
    KeyConditionExpression='userId = :user',
    ExpressionAttributeValues={':user': 'participant_001'},
    ScanIndexForward=False,
    Limit=1
)

# Record device state
table.put_item(Item={
    'userId': user_id,
    'timestamp': timestamp,
    'groupCode': group_code,
    'batteryLevel': battery_level,
    'batteryCharging': is_charging,
    'networkType': network_type,
    'storageAvailable': storage_available,
    'storageTotal': storage_total,
    'memoryAvailable': memory_available,
    'memoryTotal': memory_total,
    'appVersion': app_version,
    'osVersion': os_version,
    'expirationTime': int(time.time()) + 7776000
})
```

---

## Time-To-Live (TTL)

All tables except ParticipantStatus have TTL enabled:

- **Attribute**: `expirationTime`
- **Default**: 90 days from item creation
- **Purpose**: Automatically delete old data to control costs

**Setting TTL**:
```python
expiration_time = int(time.time()) + (90 * 24 * 60 * 60)  # 90 days
```

**Note**: ParticipantStatus doesn't have TTL as we want to keep participant records indefinitely.

---

## Access Patterns

### 1. Real-time Data Collection (Mobile Apps)

**Write Pattern**:
```python
# Batch write sensor readings
with sensor_table.batch_writer() as batch:
    for reading in readings:
        batch.put_item(Item=reading)

# Log event
event_table.put_item(Item=event)

# Update participant last seen
participant_table.update_item(
    Key={'userId': user_id},
    UpdateExpression='SET lastSeenTimestamp = :ts',
    ExpressionAttributeValues={':ts': timestamp}
)
```

### 2. Data Analysis (OSRPData)

**Read Pattern**:
```python
# Get sensor data for date range
paginator = sensor_table.query(
    KeyConditionExpression='userIdSensorType = :key AND #ts BETWEEN :start AND :end',
    ExpressionAttributeNames={'#ts': 'timestamp'},
    ExpressionAttributeValues={
        ':key': f'{user_id}#accelerometer',
        ':start': start_timestamp,
        ':end': end_timestamp
    }
)

# Convert to DataFrame
import pandas as pd
items = []
for page in paginator:
    items.extend(page['Items'])
df = pd.DataFrame(items)
```

### 3. Study Monitoring (Dashboard)

**Read Pattern**:
```python
# Get active participants
response = participant_table.query(
    IndexName='groupCode-lastSeen-index',
    KeyConditionExpression='groupCode = :group AND lastSeenTimestamp > :cutoff',
    ExpressionAttributeValues={
        ':group': 'study_001',
        ':cutoff': int(time.time() * 1000) - 86400000  # Last 24 hours
    }
)

# Get failed uploads for debugging
response = event_table.query(
    IndexName='groupCode-eventType-index',
    KeyConditionExpression='groupCode = :group AND eventType = :type',
    ExpressionAttributeValues={
        ':group': 'study_001',
        ':type': 'data_upload_failed'
    }
)
```

---

## Capacity Planning

### MVP (Pay-per-Request)

For MVP, using **PAY_PER_REQUEST** (on-demand) billing:

**Estimated Costs** (per participant/month):
- Writes: ~10,000 sensor readings/day = ~$0.30/month
- Reads: ~1,000 queries/month = ~$0.03/month
- Storage: ~50 MB = ~$0.01/month
- **Total**: ~$0.35/participant/month

**Assumptions**:
- 1 sensor collecting at 5 Hz
- Batch writes of 100 readings
- 90-day TTL (data auto-deleted)
- Minimal read queries

### Production (Provisioned Capacity)

For 100+ participants, switch to provisioned capacity:

**Per Table**:
- Read: 10 RCU = $0.07/day
- Write: 10 WCU = $0.07/day
- Auto-scaling enabled
- **Total**: ~$8-15/month for all tables

---

## CloudFormation Deployment

### Deploy Tables

```bash
# Validate template
aws cloudformation validate-template \
  --template-body file://infrastructure/cloudformation-dynamodb.yaml

# Deploy to dev environment
aws cloudformation create-stack \
  --stack-name osrp-dynamodb-dev \
  --template-body file://infrastructure/cloudformation-dynamodb.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=StudyName,ParameterValue=osrp \
  --region us-west-2

# Check status
aws cloudformation describe-stacks \
  --stack-name osrp-dynamodb-dev \
  --region us-west-2 \
  --query 'Stacks[0].StackStatus'

# Get table names
aws cloudformation describe-stacks \
  --stack-name osrp-dynamodb-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs'
```

### Update Stack

```bash
aws cloudformation update-stack \
  --stack-name osrp-dynamodb-dev \
  --template-body file://infrastructure/cloudformation-dynamodb.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=StudyName,ParameterValue=osrp \
  --region us-west-2
```

### Delete Stack

```bash
# WARNING: This will delete all data!
aws cloudformation delete-stack \
  --stack-name osrp-dynamodb-dev \
  --region us-west-2
```

---

## Testing

### Create Test Data

```python
import boto3
import time

dynamodb = boto3.resource('dynamodb', region_name='us-west-2')

# Test participant
participant_table = dynamodb.Table('osrp-ParticipantStatus-dev')
participant_table.put_item(Item={
    'userId': 'test_participant_001',
    'groupCode': 'test_study',
    'email': 'test@example.com',
    'enrolledAt': int(time.time() * 1000),
    'lastSeenTimestamp': int(time.time() * 1000),
    'deviceInfo': {
        'deviceModel': 'Test Device',
        'osVersion': 'Test OS',
        'appVersion': '0.3.0',
        'platform': 'test'
    },
    'dataCollectionStatus': 'active',
    'sensorCount': 1
})

# Test sensor data
sensor_table = dynamodb.Table('osrp-SensorTimeSeries-dev')
for i in range(10):
    sensor_table.put_item(Item={
        'userIdSensorType': 'test_participant_001#accelerometer',
        'timestamp': int((time.time() - i) * 1000),
        'groupCode': 'test_study',
        'data': {
            'x': 0.1 * i,
            'y': -9.8,
            'z': 0.2 * i
        },
        'accuracy': 3,
        'expirationTime': int(time.time()) + 7776000
    })

print("Test data created successfully")
```

### Query Test Data

```python
# Query sensor data
response = sensor_table.query(
    KeyConditionExpression='userIdSensorType = :key',
    ExpressionAttributeValues={
        ':key': 'test_participant_001#accelerometer'
    }
)

print(f"Found {len(response['Items'])} sensor readings")
for item in response['Items']:
    print(f"Timestamp: {item['timestamp']}, Data: {item['data']}")
```

---

## Next Steps

1. ✅ Schema designed
2. ✅ CloudFormation template created
3. ✅ Documentation complete
4. ⏭️ Deploy to AWS dev environment (Issue #8)
5. ⏭️ Test with sample data
6. ⏭️ Integrate with Lambda functions (Issues #4, #5)

---

**Schema Version**: 0.2.0 (MVP)
**Last Updated**: January 16, 2026
**Related Issues**: #1, #4, #5, #8
