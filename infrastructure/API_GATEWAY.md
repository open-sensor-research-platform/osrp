# OSRP API Gateway

## Overview

AWS API Gateway REST API for OSRP mobile apps with Cognito authentication.

**CloudFormation Template**: `cloudformation-api-gateway.yaml`
**Version**: 0.2.0 (MVP)

---

## API Endpoint

**Format**: `https://{api-id}.execute-api.{region}.amazonaws.com/{stage}`

**Example**: `https://abc123xyz.execute-api.us-west-2.amazonaws.com/dev`

---

## Endpoints

### Authentication Endpoints (No Auth Required)

| Method | Path | Description | Auth Required |
|--------|------|-------------|---------------|
| POST | /auth/register | Register new user | ❌ No |
| POST | /auth/login | User login | ❌ No |
| POST | /auth/refresh | Refresh tokens | ❌ No |

### Data Upload Endpoints (Auth Required)

| Method | Path | Description | Auth Required |
|--------|------|-------------|---------------|
| POST | /data/sensor | Upload sensor data | ✅ Yes |
| POST | /data/event | Log events | ✅ Yes |
| POST | /data/device-state | Upload device state | ✅ Yes |
| GET | /data/presigned-url | Get presigned S3 URL | ✅ Yes |

---

## Authentication

### Cognito User Pool Authorizer

Protected endpoints (`/data/*`) require a valid JWT token from Cognito.

**Header**:
```
Authorization: Bearer <access_token>
```

**Token Validation**:
- Token signature verified against Cognito JWKS
- Token expiration checked (60 minutes)
- User pool ID validated

**Example**:
```bash
curl -X POST $API_ENDPOINT/data/sensor \
  -H "Authorization: Bearer eyJraWQiOiI..." \
  -H "Content-Type: application/json" \
  -d '{"sensorType":"accelerometer","readings":[...],"studyCode":"test"}'
```

---

## CORS Configuration

All endpoints support CORS for mobile app access.

**Headers**:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Content-Type,Authorization
Access-Control-Allow-Methods: GET,POST,OPTIONS
```

**Preflight Requests**:
- All endpoints support `OPTIONS` method
- Returns 200 with CORS headers
- No authentication required for OPTIONS

**Example Preflight**:
```bash
curl -X OPTIONS $API_ENDPOINT/data/sensor \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Authorization"
```

---

## Rate Limiting

API Gateway throttling configured per stage:

**Limits**:
- **Rate Limit**: 10,000 requests/second (steady state)
- **Burst Limit**: 5,000 requests (token bucket)

**Exceeded Limits**:
- Returns HTTP 429 Too Many Requests
- Retry after exponential backoff

**Per-Method Limits** (Future):
```yaml
/auth/login:
  RateLimit: 100 req/sec  # Prevent brute force
/data/sensor:
  RateLimit: 1000 req/sec  # High volume data uploads
```

---

## API Structure

### Resources

```
/
├── /auth
│   ├── /register
│   ├── /login
│   └── /refresh
└── /data
    ├── /sensor
    ├── /event
    ├── /device-state
    └── /presigned-url
```

### Integration Type

All endpoints use **AWS_PROXY** integration:
- Lambda receives full API Gateway event
- Lambda returns API Gateway response format
- No request/response mapping templates needed

---

## Deployment

### Prerequisites

Deploy in order:
1. ✅ Cognito stack
2. ✅ Lambda Auth stack
3. ✅ Lambda Data Upload stack
4. ⏭️ API Gateway stack (this)

### Deploy Stack

```bash
# Validate template
aws cloudformation validate-template \
  --template-body file://infrastructure/cloudformation-api-gateway.yaml

# Create stack
aws cloudformation create-stack \
  --stack-name osrp-api-gateway-dev \
  --template-body file://infrastructure/cloudformation-api-gateway.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=StudyName,ParameterValue=osrp \
    ParameterKey=CognitoStackName,ParameterValue=osrp-cognito-dev \
    ParameterKey=AuthLambdaStackName,ParameterValue=osrp-lambda-auth-dev \
    ParameterKey=DataUploadLambdaStackName,ParameterValue=osrp-lambda-data-upload-dev \
  --region us-west-2

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name osrp-api-gateway-dev \
  --region us-west-2

# Get API endpoint
aws cloudformation describe-stacks \
  --stack-name osrp-api-gateway-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs[?OutputKey==`RestApiEndpoint`].OutputValue' \
  --output text
```

### Export API Endpoint

```bash
# Save to environment variable
export API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name osrp-api-gateway-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs[?OutputKey==`RestApiEndpoint`].OutputValue' \
  --output text)

echo $API_ENDPOINT
```

---

## Testing

### Test Authentication Endpoints

#### Register User

```bash
curl -X POST $API_ENDPOINT/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "studyCode": "test_study",
    "participantId": "TEST001"
  }' | jq .
```

**Expected Response**:
```json
{
  "message": "User registered successfully",
  "userSub": "550e8400-e29b-41d4-a716-446655440000",
  "userConfirmed": false,
  "email": "test@example.com"
}
```

#### Confirm User (Admin)

```bash
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id <user-pool-id> \
  --username test@example.com \
  --region us-west-2
```

#### Login

```bash
curl -X POST $API_ENDPOINT/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }' | jq .
```

**Expected Response**:
```json
{
  "accessToken": "eyJraWQiOiI...",
  "idToken": "eyJraWQiOiJ...",
  "refreshToken": "eyJjdHkiOi...",
  "expiresIn": 3600,
  "tokenType": "Bearer"
}
```

#### Save Access Token

```bash
export ACCESS_TOKEN=$(curl -s -X POST $API_ENDPOINT/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }' | jq -r '.accessToken')

echo $ACCESS_TOKEN
```

### Test Data Upload Endpoints

#### Upload Sensor Data

```bash
curl -X POST $API_ENDPOINT/data/sensor \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sensorType": "accelerometer",
    "readings": [
      {
        "timestamp": 1705334400123,
        "data": {"x": 0.234, "y": -9.812, "z": 0.156},
        "accuracy": 3
      }
    ],
    "studyCode": "test_study"
  }' | jq .
```

**Expected Response**:
```json
{
  "message": "Sensor data uploaded successfully",
  "count": 1,
  "sensorType": "accelerometer"
}
```

#### Log Event

```bash
curl -X POST $API_ENDPOINT/data/event \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "eventType": "app_launch",
    "timestamp": 1705334400123,
    "studyCode": "test_study"
  }' | jq .
```

#### Get Presigned URL

```bash
curl -X GET "$API_ENDPOINT/data/presigned-url?key=raw/screenshots/test-user/file.png&contentType=image/png" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq .
```

**Expected Response**:
```json
{
  "uploadUrl": "https://osrp-data-dev-123456789012.s3.amazonaws.com/...",
  "key": "raw/screenshots/test-user/file.png",
  "expiresIn": 3600
}
```

### Test Authentication Failures

#### Missing Token

```bash
curl -X POST $API_ENDPOINT/data/sensor \
  -H "Content-Type: application/json" \
  -d '{"sensorType":"accelerometer","readings":[],"studyCode":"test"}'
```

**Expected**: HTTP 401 Unauthorized

#### Invalid Token

```bash
curl -X POST $API_ENDPOINT/data/sensor \
  -H "Authorization: Bearer invalid-token" \
  -H "Content-Type: application/json" \
  -d '{"sensorType":"accelerometer","readings":[],"studyCode":"test"}'
```

**Expected**: HTTP 401 Unauthorized

#### Expired Token

```bash
# Wait 61 minutes after login
curl -X POST $API_ENDPOINT/data/sensor \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sensorType":"accelerometer","readings":[],"studyCode":"test"}'
```

**Expected**: HTTP 401 Unauthorized

**Solution**: Refresh token
```bash
curl -X POST $API_ENDPOINT/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH_TOKEN\"}"
```

---

## Monitoring

### CloudWatch Metrics

API Gateway publishes metrics to CloudWatch:

**Key Metrics**:
- `Count` - Total API requests
- `4XXError` - Client errors
- `5XXError` - Server errors
- `Latency` - Request processing time
- `IntegrationLatency` - Lambda execution time

**View Metrics**:
```bash
# API calls per hour
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --dimensions Name=ApiName,Value=osrp-api-dev \
  --start-time 2026-01-16T00:00:00Z \
  --end-time 2026-01-16T23:59:59Z \
  --period 3600 \
  --statistics Sum \
  --region us-west-2

# Error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name 4XXError \
  --dimensions Name=ApiName,Value=osrp-api-dev \
  --start-time 2026-01-16T00:00:00Z \
  --end-time 2026-01-16T23:59:59Z \
  --period 3600 \
  --statistics Sum \
  --region us-west-2
```

### CloudWatch Logs

API Gateway logs requests:

**Log Group**: `/aws/apigateway/osrp-api-dev`

**Log Format**:
```
2026-01-16T12:00:00.000Z request-id Extended Request Id
{
  "requestId": "abc-123",
  "ip": "203.0.113.0",
  "caller": "-",
  "user": "550e8400-e29b-41d4-a716-446655440000",
  "requestTime": "16/Jan/2026:12:00:00 +0000",
  "httpMethod": "POST",
  "resourcePath": "/data/sensor",
  "status": "200",
  "protocol": "HTTP/1.1",
  "responseLength": "123"
}
```

**View Logs**:
```bash
aws logs tail /aws/apigateway/osrp-api-dev \
  --follow \
  --region us-west-2
```

### X-Ray Tracing (Optional)

Enable X-Ray for request tracing:

```yaml
ApiStage:
  Properties:
    TracingEnabled: true
```

**View Traces**:
```bash
aws xray get-trace-summaries \
  --start-time 2026-01-16T00:00:00 \
  --end-time 2026-01-16T23:59:59 \
  --region us-west-2
```

---

## Cost Estimation

### API Gateway Pricing

**Free Tier** (first 12 months):
- 1 million API calls/month - FREE

**Beyond Free Tier**:
- $3.50 per million API calls (first 333 million)
- $2.80 per million (next 667 million)
- $2.38 per million (over 1 billion)

### MVP Cost (10 participants)

**Assumptions**:
- 100 API calls/day/participant
- 30,000 API calls/month

**Cost**: FREE (within free tier)

### Production Cost (100 participants)

**Assumptions**:
- 100 API calls/day/participant
- 300,000 API calls/month

**Cost**:
- API calls: 0.3M × $3.50/M = $1.05/month
- Data transfer: ~$0.05/month
- **Total**: ~$1.10/month

---

## Security Best Practices

### 1. Use HTTPS Only

API Gateway enforces HTTPS by default. Never use HTTP.

### 2. Validate Tokens

Tokens are validated by Cognito authorizer automatically:
- Signature verification
- Expiration check
- Issuer validation

### 3. Rate Limiting

Configure per-method throttling for sensitive endpoints:

```yaml
MethodSettings:
  - ResourcePath: '/auth/login'
    HttpMethod: 'POST'
    ThrottlingBurstLimit: 100
    ThrottlingRateLimit: 50
```

### 4. Request Validation (Future)

Add request validators:
```yaml
RequestValidator:
  Type: AWS::ApiGateway::RequestValidator
  Properties:
    ValidateRequestBody: true
    ValidateRequestParameters: true
```

### 5. API Keys (Optional)

For additional security, require API keys:

```yaml
ApiKey:
  Type: AWS::ApiGateway::ApiKey
  Properties:
    Enabled: true

UsagePlan:
  Type: AWS::ApiGateway::UsagePlan
  Properties:
    UsagePlanName: osrp-usage-plan
    Throttle:
      BurstLimit: 5000
      RateLimit: 10000
```

---

## Troubleshooting

### Issue: 403 Forbidden

**Cause**: Lambda doesn't have permission to be invoked by API Gateway

**Fix**: Check Lambda permissions
```bash
aws lambda get-policy \
  --function-name osrp-auth-dev \
  --region us-west-2
```

Should include:
```json
{
  "Principal": "apigateway.amazonaws.com",
  "Action": "lambda:InvokeFunction"
}
```

### Issue: 401 Unauthorized on data endpoints

**Cause**: Missing or invalid access token

**Fix**:
1. Check Authorization header format: `Bearer <token>`
2. Verify token hasn't expired (60 minutes)
3. Refresh token if needed

### Issue: CORS errors in browser

**Cause**: Missing CORS headers or preflight response

**Fix**:
1. Verify OPTIONS method exists for endpoint
2. Check CORS headers in Lambda response
3. Redeploy API after changes

### Issue: 502 Bad Gateway

**Cause**: Lambda error or timeout

**Fix**:
1. Check Lambda CloudWatch logs
2. Verify Lambda environment variables
3. Test Lambda function directly

---

## API Documentation

### OpenAPI Specification

Export API definition:

```bash
aws apigateway get-export \
  --rest-api-id <api-id> \
  --stage-name dev \
  --export-type swagger \
  --accepts application/json \
  --region us-west-2 \
  > api-spec.json
```

### Postman Collection

Import OpenAPI spec into Postman:
1. Open Postman
2. Import → Upload Files
3. Select `api-spec.json`
4. Set environment variables:
   - `api_endpoint`: Your API Gateway URL
   - `access_token`: Your Cognito token

---

## Stage Management

### Create New Stage

```bash
# Create staging deployment
aws apigateway create-deployment \
  --rest-api-id <api-id> \
  --stage-name staging \
  --description "Staging environment" \
  --region us-west-2
```

### Stage Variables

Use stage variables for environment-specific configuration:

```yaml
StageVariables:
  lambdaAlias: ${Environment}
  dynamoTableSuffix: ${Environment}
```

**Access in Lambda**:
```python
stage = event['requestContext']['stage']
table_suffix = event['stageVariables']['dynamoTableSuffix']
```

---

## Next Steps

1. ✅ API Gateway configured
2. ✅ Routes and methods created
3. ✅ Cognito authorizer attached
4. ✅ CORS enabled
5. ✅ Rate limiting configured
6. ✅ Documentation complete
7. ⏭️ Deploy to AWS dev environment (Issue #8)
8. ⏭️ Test end-to-end flow
9. ⏭️ Integrate with mobile apps (Issues #11, #18)

---

**API Gateway Version**: 0.2.0 (MVP)
**Last Updated**: January 16, 2026
**Related Issues**: #6, #8, #11, #18
