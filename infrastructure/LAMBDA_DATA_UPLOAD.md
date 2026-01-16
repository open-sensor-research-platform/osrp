# OSRP Data Upload Lambda Function

## Overview

AWS Lambda function for uploading sensor data, events, and device state from mobile apps.

**Handler File**: `lambda/data_upload_handler.py`
**CloudFormation Template**: `cloudformation-lambda-data-upload.yaml`
**Runtime**: Python 3.11
**Memory**: 512 MB
**Timeout**: 30 seconds
**Version**: 0.2.0 (MVP)

---

## Endpoints

### POST /data/sensor

Upload sensor time series data (accelerometer, gyroscope, etc.).

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request**:
```json
{
  "sensorType": "accelerometer",
  "readings": [
    {
      "timestamp": 1705334400123,
      "data": {"x": 0.234, "y": -9.812, "z": 0.156},
      "accuracy": 3
    },
    {
      "timestamp": 1705334400323,
      "data": {"x": 0.240, "y": -9.810, "z": 0.160},
      "accuracy": 3
    }
  ],
  "studyCode": "depression_study_2026"
}
```

**Response (200)**:
```json
{
  "message": "Sensor data uploaded successfully",
  "count": 2,
  "sensorType": "accelerometer"
}
```

**Limits**:
- Maximum 1000 readings per request
- Batch uploads encouraged for efficiency

**Error Responses**:
- `400` - Invalid data or too many readings
- `401` - Unauthorized (invalid token)
- `500` - Database error

---

### POST /data/event

Log discrete events (app launches, interactions, etc.).

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request**:
```json
{
  "eventType": "app_launch",
  "timestamp": 1705334400123,
  "eventData": {
    "appVersion": "0.3.0",
    "sessionId": "abc123"
  },
  "context": {
    "batteryLevel": 85,
    "networkType": "wifi"
  },
  "studyCode": "depression_study_2026"
}
```

**Response (200)**:
```json
{
  "message": "Event logged successfully",
  "eventType": "app_launch",
  "timestamp": 1705334400123
}
```

**Event Types** (MVP):
- `app_launch` - App started
- `app_background` - App moved to background
- `data_upload_start` - Upload initiated
- `data_upload_success` - Upload completed
- `data_upload_failed` - Upload failed
- `sensor_start` - Sensor collection started
- `sensor_stop` - Sensor collection stopped

---

### POST /data/device-state

Upload device state snapshot.

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request**:
```json
{
  "timestamp": 1705334400000,
  "studyCode": "depression_study_2026",
  "batteryLevel": 85,
  "batteryCharging": false,
  "networkType": "wifi",
  "storageAvailable": 5368709120,
  "storageTotal": 10737418240,
  "memoryAvailable": 2147483648,
  "memoryTotal": 4294967296,
  "appVersion": "0.3.0",
  "osVersion": "Fire OS 8"
}
```

**Response (200)**:
```json
{
  "message": "Device state uploaded successfully",
  "timestamp": 1705334400000
}
```

---

### GET /data/presigned-url

Generate presigned S3 URL for direct file upload.

**Headers**:
```
Authorization: Bearer <access_token>
```

**Query Parameters**:
- `key` (required): S3 object key (e.g., `raw/screenshots/user-123/2026-01-16/file.png`)
- `contentType` (optional): MIME type (default: `application/octet-stream`)
- `expiresIn` (optional): URL expiration in seconds (default: `3600`)

**Example**:
```
GET /data/presigned-url?key=raw/screenshots/user-123/2026-01-16/screenshot.png&contentType=image/png
```

**Response (200)**:
```json
{
  "uploadUrl": "https://osrp-data-dev-123456789012.s3.amazonaws.com/...",
  "key": "raw/screenshots/user-123/2026-01-16/screenshot.png",
  "expiresIn": 3600
}
```

**Usage**:
```bash
# 1. Get presigned URL from Lambda
curl -X GET "$API_ENDPOINT/data/presigned-url?key=raw/screenshots/user-123/file.png" \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# 2. Upload file directly to S3
curl -X PUT "$PRESIGNED_URL" \
  -H "Content-Type: image/png" \
  --data-binary @screenshot.png
```

**Security**:
- Key must start with `raw/` or `temp/`
- Key must contain user ID (prevents unauthorized access)
- URL expires after specified duration (default 1 hour)

---

## Mobile App Integration

### Android (Kotlin)

**Upload Sensor Data**:
```kotlin
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.MediaType.Companion.toMediaType
import org.json.JSONObject
import org.json.JSONArray

class DataUploader(
    private val apiEndpoint: String,
    private val accessToken: String
) {
    private val client = OkHttpClient()
    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()

    fun uploadSensorData(
        sensorType: String,
        readings: List<SensorReading>,
        studyCode: String
    ): Boolean {
        val readingsJson = JSONArray()
        for (reading in readings) {
            readingsJson.put(JSONObject().apply {
                put("timestamp", reading.timestamp)
                put("data", JSONObject(reading.data))
                put("accuracy", reading.accuracy)
            })
        }

        val body = JSONObject().apply {
            put("sensorType", sensorType)
            put("readings", readingsJson)
            put("studyCode", studyCode)
        }.toString().toRequestBody(jsonMediaType)

        val request = Request.Builder()
            .url("$apiEndpoint/data/sensor")
            .addHeader("Authorization", "Bearer $accessToken")
            .post(body)
            .build()

        return try {
            client.newCall(request).execute().use { response ->
                response.isSuccessful
            }
        } catch (e: Exception) {
            Log.e("DataUploader", "Upload failed", e)
            false
        }
    }

    fun logEvent(
        eventType: String,
        timestamp: Long,
        eventData: Map<String, Any>,
        studyCode: String
    ): Boolean {
        val body = JSONObject().apply {
            put("eventType", eventType)
            put("timestamp", timestamp)
            put("eventData", JSONObject(eventData))
            put("studyCode", studyCode)
        }.toString().toRequestBody(jsonMediaType)

        val request = Request.Builder()
            .url("$apiEndpoint/data/event")
            .addHeader("Authorization", "Bearer $accessToken")
            .post(body)
            .build()

        return try {
            client.newCall(request).execute().use { response ->
                response.isSuccessful
            }
        } catch (e: Exception) {
            Log.e("DataUploader", "Event log failed", e)
            false
        }
    }
}

data class SensorReading(
    val timestamp: Long,
    val data: Map<String, Float>,
    val accuracy: Int
)
```

**Upload File via Presigned URL**:
```kotlin
suspend fun uploadFile(
    file: File,
    key: String,
    contentType: String
): Boolean = withContext(Dispatchers.IO) {
    try {
        // 1. Get presigned URL
        val urlRequest = Request.Builder()
            .url("$apiEndpoint/data/presigned-url?key=$key&contentType=$contentType")
            .addHeader("Authorization", "Bearer $accessToken")
            .get()
            .build()

        val presignedUrl = client.newCall(urlRequest).execute().use { response ->
            if (!response.isSuccessful) return@withContext false
            val json = JSONObject(response.body!!.string())
            json.getString("uploadUrl")
        }

        // 2. Upload file to S3
        val fileBody = file.readBytes().toRequestBody(contentType.toMediaType())
        val uploadRequest = Request.Builder()
            .url(presignedUrl)
            .put(fileBody)
            .build()

        client.newCall(uploadRequest).execute().use { response ->
            response.isSuccessful
        }
    } catch (e: Exception) {
        Log.e("DataUploader", "File upload failed", e)
        false
    }
}
```

### iOS (Swift)

**Upload Sensor Data**:
```swift
import Foundation

class DataUploader {
    let apiEndpoint: String
    let accessToken: String

    init(apiEndpoint: String, accessToken: String) {
        self.apiEndpoint = apiEndpoint
        self.accessToken = accessToken
    }

    func uploadSensorData(
        sensorType: String,
        readings: [[String: Any]],
        studyCode: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard let url = URL(string: "\(apiEndpoint)/data/sensor") else {
            completion(false)
            return
        }

        let body: [String: Any] = [
            "sensorType": sensorType,
            "readings": readings,
            "studyCode": studyCode
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload failed: \(error)")
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                completion(httpResponse.statusCode == 200)
            } else {
                completion(false)
            }
        }.resume()
    }
}
```

---

## Data Format

### Sensor Data Storage

Data is stored in DynamoDB SensorTimeSeries table:

```python
{
    'userIdSensorType': 'participant_001#accelerometer',  # Partition key
    'timestamp': 1705334400123,                            # Sort key
    'groupCode': 'depression_study_2026',
    'data': {
        'x': Decimal('0.234'),
        'y': Decimal('-9.812'),
        'z': Decimal('0.156')
    },
    'accuracy': 3,
    'expirationTime': 1712937600  # TTL: 90 days
}
```

### Event Data Storage

Data is stored in DynamoDB EventLog table:

```python
{
    'userId': 'participant_001',                           # Partition key
    'timestampEventType': '1705334400123#app_launch',     # Sort key
    'groupCode': 'depression_study_2026',
    'eventType': 'app_launch',
    'eventData': {
        'appVersion': '0.3.0',
        'sessionId': 'abc123'
    },
    'context': {
        'batteryLevel': Decimal('85'),
        'networkType': 'wifi'
    },
    'expirationTime': 1712937600  # TTL: 90 days
}
```

---

## Deployment

### Package Lambda Code

```bash
# From infrastructure/lambda directory
cd infrastructure/lambda

# Create deployment package
zip -r data_upload_handler.zip data_upload_handler.py

# Upload to S3 (if code is large)
aws s3 cp data_upload_handler.zip s3://osrp-deployment-us-west-2/lambda/
```

### Deploy CloudFormation Stack

```bash
# Validate template
aws cloudformation validate-template \
  --template-body file://infrastructure/cloudformation-lambda-data-upload.yaml

# Create stack
aws cloudformation create-stack \
  --stack-name osrp-lambda-data-upload-dev \
  --template-body file://infrastructure/cloudformation-lambda-data-upload.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=StudyName,ParameterValue=osrp \
    ParameterKey=DynamoDBStackName,ParameterValue=osrp-dynamodb-dev \
    ParameterKey=S3StackName,ParameterValue=osrp-s3-dev \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-west-2

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name osrp-lambda-data-upload-dev \
  --region us-west-2
```

### Update Lambda Code

```bash
# Update function code
aws lambda update-function-code \
  --function-name osrp-data-upload-dev \
  --zip-file fileb://data_upload_handler.zip \
  --region us-west-2
```

---

## Testing

### Unit Tests

```bash
# Run tests
pytest tests/lambda/test_data_upload_handler.py -v

# With coverage
pytest tests/lambda/test_data_upload_handler.py --cov=data_upload_handler
```

### Integration Testing

#### Test Sensor Upload

```bash
# Get function name
FUNCTION_NAME=$(aws cloudformation describe-stacks \
  --stack-name osrp-lambda-data-upload-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs[?OutputKey==`DataUploadLambdaFunctionName`].OutputValue' \
  --output text)

# Invoke Lambda
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload '{
    "httpMethod": "POST",
    "path": "/data/sensor",
    "body": "{\"sensorType\":\"accelerometer\",\"readings\":[{\"timestamp\":1705334400123,\"data\":{\"x\":0.234,\"y\":-9.812,\"z\":0.156},\"accuracy\":3}],\"studyCode\":\"test_study\"}",
    "requestContext": {
      "authorizer": {
        "claims": {"sub": "test-user-001"}
      }
    }
  }' \
  --region us-west-2 \
  response.json

cat response.json | jq .
```

#### Test Event Upload

```bash
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload '{
    "httpMethod": "POST",
    "path": "/data/event",
    "body": "{\"eventType\":\"app_launch\",\"timestamp\":1705334400123,\"studyCode\":\"test_study\"}",
    "requestContext": {
      "authorizer": {
        "claims": {"sub": "test-user-001"}
      }
    }
  }' \
  --region us-west-2 \
  response.json
```

#### Verify Data in DynamoDB

```bash
# Query sensor data
aws dynamodb query \
  --table-name osrp-SensorTimeSeries-dev \
  --key-condition-expression "userIdSensorType = :key" \
  --expression-attribute-values '{":key":{"S":"test-user-001#accelerometer"}}' \
  --region us-west-2
```

---

## CloudWatch Logs

### View Logs

```bash
LOG_GROUP="/aws/lambda/osrp-data-upload-dev"

# Tail logs
aws logs tail $LOG_GROUP --follow --region us-west-2

# Search for errors
aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --filter-pattern "ERROR" \
  --region us-west-2
```

### Log Format

```
[INFO] 2026-01-16T12:00:00.000Z request-id Uploading 100 accelerometer readings for user participant_001
[INFO] 2026-01-16T12:00:01.000Z request-id Successfully uploaded 100 accelerometer readings
```

---

## Error Handling

### Client Errors (4xx)

| Code | Error | Description |
|------|-------|-------------|
| 400 | Invalid JSON | Request body not valid JSON |
| 400 | Invalid data | Missing required fields or invalid format |
| 400 | Too many readings | More than 1000 readings in single request |
| 401 | Unauthorized | Invalid or missing access token |
| 403 | Forbidden | User ID not in presigned URL key |
| 404 | Not found | Invalid endpoint |

### Server Errors (5xx)

| Code | Error | Description |
|------|-------|-------------|
| 500 | Database error | DynamoDB write failed |
| 500 | S3 error | S3 presigned URL generation failed |

---

## Performance

### Benchmarks

Expected performance (warm Lambda):
- Sensor upload (10 readings): 100-200ms
- Sensor upload (100 readings): 200-400ms
- Sensor upload (1000 readings): 500-800ms
- Event upload: 50-100ms
- Presigned URL: 50-100ms

### Optimization Tips

1. **Batch sensor readings**: Upload 100-1000 readings per request
2. **Use batch writer**: DynamoDB batch operations are more efficient
3. **Upload files directly to S3**: Use presigned URLs, not Lambda
4. **Monitor Lambda concurrency**: Scale as needed

---

## Cost Estimation

### Lambda Pricing

**MVP Cost** (10 participants):
- Sensor uploads: ~100 requests/day/participant = 30,000/month
- Memory: 512 MB, Duration: 200ms average
- Compute: 30,000 × 0.5 GB × 0.2s = 3,000 GB-seconds
- **Cost**: FREE (within free tier)

**Production Cost** (100 participants):
- Sensor uploads: ~100 requests/day/participant = 300,000/month
- Compute: 300,000 × 0.5 GB × 0.2s = 30,000 GB-seconds
- Requests: 300,000 × $0.20/1M = $0.06
- Compute: 30,000 × $0.0000166667 = $0.50
- **Total**: ~$0.56/month

### DynamoDB Costs

With PAY_PER_REQUEST:
- Write requests: 300,000 × $1.25/million = $0.38
- Storage: ~50 MB × $0.25/GB = ~$0.01

**Total Data Upload Cost**: ~$1/month for 100 participants

---

## Security

### Authentication

- All endpoints require valid JWT access token
- User ID extracted from token claims
- Token validated by API Gateway authorizer

### Authorization

- User ID must match data being uploaded
- Presigned URLs validated for user ID presence
- S3 keys restricted to `raw/` and `temp/` prefixes

### Data Validation

- Required fields checked
- Data types validated
- Maximum limits enforced (1000 readings/request)
- Float values converted to Decimal for DynamoDB

---

## Monitoring

### CloudWatch Metrics

Key metrics:
- `Invocations` - Total uploads
- `Errors` - Failed uploads
- `Duration` - Processing time
- `Throttles` - Rate limiting

### Custom Metrics

Log custom business metrics:
```python
cloudwatch = boto3.client('cloudwatch')

cloudwatch.put_metric_data(
    Namespace='OSRP/DataUpload',
    MetricData=[
        {
            'MetricName': 'SensorReadingsUploaded',
            'Value': len(readings),
            'Unit': 'Count'
        }
    ]
)
```

---

## Troubleshooting

### Issue: Float to Decimal conversion errors

**Cause**: DynamoDB doesn't support float type
**Fix**: Use `convert_floats_to_decimal()` helper

### Issue: Batch write fails

**Cause**: Individual item exceeds 400 KB
**Fix**: Reduce batch size or split large data

### Issue: Presigned URL access denied

**Cause**: User ID not in S3 key
**Fix**: Ensure key contains user ID

### Issue: TTL not deleting old data

**Cause**: TTL attribute not set or disabled
**Fix**: Verify `expirationTime` is set and TTL enabled on table

---

## Next Steps

1. ✅ Lambda function implemented
2. ✅ Unit tests created
3. ✅ CloudFormation template created
4. ✅ Documentation complete
5. ⏭️ Deploy to AWS dev environment (Issue #8)
6. ⏭️ Test data upload flow
7. ⏭️ Integrate with API Gateway (Issue #6)
8. ⏭️ Integrate with mobile apps (Issues #11, #18)

---

**Lambda Version**: 0.2.0 (MVP)
**Last Updated**: January 16, 2026
**Related Issues**: #5, #6, #8, #11, #18
